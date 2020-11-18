from flask import url_for, redirect, render_template, abort, request
from app import app, mongo, mysql
from app.util import convert_flat_to_hierarchical
import datetime
import random

def execute_query(*args, **kwargs):
    cursor = mysql.connection.cursor()
    cursor.execute(*args, **kwargs)
    result = cursor.fetchall()
    return result

def get_titles(asins):
    if asins is not None:
        result = mongo.db.kindle_metadata.find({ "asin": { "$in": asins } }, { "asin": 1, "title": 1, "_id": 0 })
        return [(book["asin"], book.get("title") or book["asin"]) for book in result]
    else:
        return []

def find_book(asin, include_related=False, include_reviews=False):
    result = mongo.db.kindle_metadata.find_one({ "asin" : asin })
    if result is None:
        return None
    book = {"asin": asin}
    book["title"] = result.get("title") or asin
    book["description"] = result.get("description") or "Description not available"
    book["imUrl"] = result.get("imUrl") or "https://images-na.ssl-images-amazon.com/images/I/61Ww4abGclL._AC_SX425_.jpg"
    book["categories"] = result.get("categories") or []
    book["categories"] = convert_flat_to_hierarchical(book["categories"])
    book["price"] = result.get("price")
    book["price"] = f"${book['price']:.2f}" if book["price"] is not None else "Price not available"
    book["salesRank"] = result.get("salesRank")
    book["salesRank"] = f"{book['salesRank']:,}" if book["salesRank"] is not None else "Sales rank not available"
    if include_related:
        book["related"] = result.get("related") or {}
        for key in book["related"]:
            book["related"][key] = get_titles(book["related"][key])
    if include_reviews:
        book["reviews"] = execute_query("""SELECT reviewId, summary FROM test.kindle_reviews WHERE asin = %s""", (asin,))
    return book

def find_review(reviewId):
    result = execute_query("""SELECT * FROM test.kindle_reviews WHERE reviewId = %s""", (reviewId,))
    if len(result) == 0:
        return None
    reviewId, asin, helpful, overall, reviewText, reviewTime, reviewerID, reviewerName, summary, unixReviewTime = result[0]
    review = find_book(asin) or {}
    review["helpfulness"] = helpful[1:-1].split(", ")
    review["helpfulness"] = review["helpfulness"] if int(review["helpfulness"][1]) > 0 else None
    review["rating"] = f"{overall} / 5"
    review["reviewText"] = reviewText
    review["reviewer"] = reviewerName
    review["summary"] = summary
    review["timestamp"] = datetime.datetime.utcfromtimestamp(unixReviewTime).strftime('%B %m, %Y')
    return review

@app.route("/book/<asin>")
def get_book(asin):
    include = request.args.getlist("include")
    include_related = "related" in include
    include_reviews = "reviews" in include
    book = find_book(asin, include_related, include_reviews)
    if book is None:
        abort(404)
    return render_template("book.html", **book)

@app.route("/review/<reviewId>")
def get_review(reviewId):
    review = find_review(reviewId)
    if review is None:
        abort(404)
    return render_template("review.html", **review)

@app.route("/random/book")
def random_book():
    query = { "$or": [
        { "title": { "$exists": 1 } },
        { "description": { "$exists": 1 } },
        { "price": { "$exists": 1 } },
        { "salesRank": { "$exists": 1 } }]}
    count = mongo.db.kindle_metadata.count(query)
    books = mongo.db.kindle_metadata.find(query)
    book = next(books.skip(random.randint(0, count)))
    asin = book["asin"]
    return redirect(url_for("get_book", asin=asin))

@app.route("/random/review")
def random_review():
    count, = execute_query("""SELECT MAX(reviewId) as maxId FROM test.kindle_reviews""")[0]
    reviewId = random.randint(0, count)
    return redirect(url_for("get_review", reviewId=reviewId))

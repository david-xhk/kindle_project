from flask import url_for, redirect, render_template, abort
from app import app, mongo, mysql

def execute_query(*args, **kwargs):
    cursor = mysql.connection.cursor()
    cursor.execute(*args, **kwargs)
    result = cursor.fetchall()
    return result

@app.route("/random/review")
def random_review():
    result = execute_query("""SELECT * FROM test.kindle_reviews LIMIT 1""")
    return str(result)

@app.route("/random/book")
def random_book():
    book = next(mongo.db.kindle_metadata.aggregate([
        { "$match": { "$or": [
            { "title": { "$exists": 1 } },
            { "description": { "$exists": 1 } },
            { "price": { "$exists": 1 } },
            { "salesRank": { "$exists": 1 } }]}},
        { "$sample" : { "size": 1 } }]))
    asin = book["asin"]
    return redirect(url_for("get_book", asin=asin))

@app.route("/review/<reviewId>")
def get_review(reviewId):
    result = execute_query("""SELECT * FROM test.kindle_reviews WHERE reviewId = %s""", (reviewId,))
    if len(result) == 0:
        abort(404)
    
    reviewId, asin, helpful, overall, reviewText, reviewTime, reviewerID, reviewerName, summary, unixReviewTime = result[0]
    return render_template("review.html",
        asin        = asin,
        title       = mongo.db.kindle_metadata.find_one({ "asin": asin }) or "Unknown",
        helpfulness = "{} out of {}".format(*helpful[1:-1].split(", ")),
        rating      = f"{overall} out of 5",
        reviewText  = reviewText,
        reviewer    = reviewerName,
        summary     = summary,
        timestamp   = datetime.utcfromtimestamp(unixReviewTime).strftime('%B %m, %Y'))

@app.route("/book/<asin>")
def get_book(asin):
    book = mongo.db.kindle_metadata.find_one_or_404({ "asin" : asin })
    return render_template("book.html",
        asin        = book["asin"],
        title       = book.get("title") or "Unknown",
        imUrl       = book.get("imUrl") or "https://images-na.ssl-images-amazon.com/images/I/61Ww4abGclL._AC_SX425_.jpg",
        description = book.get("description") or "Description not available",
        categories  = book.get("categories") or [],
        related     = book.get("related") or {},
        price       = "Price not available" if book.get("price") is None else f"${book['price']:.2f}",
        salesRank   = book.get("salesRank") or "Sales rank not available")

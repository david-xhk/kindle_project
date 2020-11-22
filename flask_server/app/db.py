from app import app, mysql, mongo
from app.util import convert_flat_to_hierarchical
import datetime
import random

def mongo_query(*args, **kwargs):
    collection = app.config["MONGO_COLLECTION"]
    return mongo.db[collection].find(*args, **kwargs)

def sql_query(*args, **kwargs):
    cursor = mysql.connection.cursor()
    cursor.execute(*args, **kwargs)
    result = cursor.fetchall()
    return result

def find_review(reviewId):
    result = sql_query("""SELECT * FROM {MYSQL_DB}.{MYSQL_TABLE} WHERE reviewId = %s""".format(**app.config), (reviewId,))
    if len(result) == 0:
        return None
    reviewId, asin, helpful, overall, reviewText, reviewTime, reviewerID, reviewerName, summary, unixReviewTime = result[0]
    review = find_book(asin, lenient=True)
    review["helpfulness"] = helpful[1:-1].split(", ")
    review["helpfulness"] = review["helpfulness"] if int(review["helpfulness"][1]) > 0 else None
    review["rating"] = "{} / 5".format(overall)
    review["reviewText"] = reviewText
    review["reviewer"] = reviewerName
    review["summary"] = summary
    review["timestamp"] = datetime.datetime.utcfromtimestamp(unixReviewTime).strftime('%B %m, %Y')
    return review

def find_book(asin, lenient=False):
    result = next(mongo_query({ "asin" : asin }), None)
    if result is None:
        if not lenient:
            return None
        else:
            result = {}
    book = {"asin": asin}
    book["title"] = result.get("title") or asin
    book["description"] = result.get("description") or "Description not available"
    book["imUrl"] = result.get("imUrl") or "https://images-na.ssl-images-amazon.com/images/I/61Ww4abGclL._AC_SX425_.jpg"
    book["categories"] = result.get("categories") or []
    book["categories"] = convert_flat_to_hierarchical(book["categories"])
    book["price"] = result.get("price")
    book["price"] = "${:.2f}".format(book['price']) if book["price"] is not None else "Price not available"
    book["salesRank"] = result.get("salesRank")
    book["salesRank"] = "{:,}".format(book['salesRank']) if book["salesRank"] is not None else "Sales rank not available"
    book["related"] = result.get("related") or {}
    for key in book["related"]:
        book["related"][key] = get_titles(book["related"][key])
    book["reviews"] = sql_query("""SELECT reviewId, summary FROM {MYSQL_DB}.{MYSQL_TABLE} WHERE asin = %s""".format(**app.config), (asin,))
    return book

def get_titles(asins):
    if asins is None:
        return []
    else:
        query = { "asin": { "$in": asins } }
        projection = { "asin": 1, "title": 1, "_id": 0 }
        result = mongo_query(query, projection)
        return [(book["asin"], book.get("title") or book["asin"]) for book in result]

def random_reviewId():
    count = sql_query("""SELECT MAX(reviewId) as maxId FROM {MYSQL_DB}.{MYSQL_TABLE}""".format(**app.config))[0][0]
    return random.randint(0, count)

def random_asin():
    count = mongo.db.kindle_metadata.count()
    books = mongo_query()
    book = next(books.skip(random.randint(0, count)))
    return book["asin"]

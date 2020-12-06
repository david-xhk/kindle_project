from app import app, mysql, mongo
from app.util import convert_flat_to_hierarchical, convert_to_base, convert_to_int, round_off, average
import datetime, time
import random

mongodb = mongo.db[app.config["MONGO_COLLECTION"]]

def sql_query(query, *args, **kwargs):
    cursor = mysql.connection.cursor()
    cursor.execute(query, *args, **kwargs)
    result = cursor.fetchall()
    mysql.connection.commit()
    return result

def add_book(book):
    max_asin = next(mongodb.find().sort("asin", -1).limit(1))["asin"]
    new_asin = convert_to_base(convert_to_int(max_asin, 36) + 1, 36)
    book["_id"] = new_asin
    book["asin"] = new_asin
    mongodb.insert(book)
    return new_asin

def add_review(review):
    max_reviewId = sql_query("""SELECT MAX(reviewId) as maxId FROM {MYSQL_DB}.{MYSQL_TABLE}""".format(**app.config))[0][0]
    new_reviewId = int(max_reviewId) + 1
    query = """INSERT INTO {MYSQL_DB}.{MYSQL_TABLE} (reviewId, asin, helpful, overall, reviewText, reviewerName, summary, unixReviewTime) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)""".format(**app.config)
    args = (new_reviewId, review["asin"], "[0, 0]", review["rating"], review["reviewText"], review["reviewer"], review["summary"], int(time.time()))
    sql_query(query, args)
    return new_reviewId

def search_book(title=None, filter_by=None, sort_by=None, order_by=None):
    query = {}
    project = { "asin": 1, "title": 1, "imUrl": 1, "price": 1, "_id": 0 }
    sort = []
    if title:
        query["$text"] = { "$search": title }
        project["score"] = { "$meta": "textScore" }
        sort.append(("score", { "$meta": "textScore" }))
    if filter_by:
        if not isinstance(filter_by, list):
            filter_by = [filter_by]
        query["categories"] = { "$elemMatch": { "$elemMatch": { "$in": filter_by } } }
    if sort_by == "price" and order_by:
        sort = [(sort_by, order_by)]
    result = mongodb.find(query, project)
    if sort:
        result = result.sort(sort)
    result = list(result)
    if result:
        asin_mapping = dict((book["asin"], i) for i, book in enumerate(result))
        mysql_result = sql_query("""SELECT asin, AVG(overall) FROM {MYSQL_DB}.{MYSQL_TABLE} WHERE asin IN %s GROUP BY asin""".format(**app.config), (list(asin_mapping),))
        for asin, rating in mysql_result:
            result[asin_mapping[asin]]["rating"] = float(rating)
        if sort_by == "rating" and order_by:
            result.sort(key=lambda book: book["rating"] * order_by if "rating" in book else 6)
        for book in result:
            book["title"] = book.get("title") or book["asin"]
            book["rating"] = "{} / 5".format(round_off(book["rating"], 2)) if book.get("rating") is not None else "Rating not available"
            book["price"] = "${}".format(round_off(book["price"], 2)) if book.get("price") is not None else "Price not available"
    return result

def find_review(reviewId):
    result = sql_query("""SELECT * FROM {MYSQL_DB}.{MYSQL_TABLE} WHERE reviewId = %s""".format(**app.config), (reviewId,))
    if len(result) == 0:
        return None
    reviewId, asin, helpful, overall, reviewText, reviewTime, reviewerID, reviewerName, summary, unixReviewTime = result[0]
    review = {}
    review["helpfulness"] = helpful[1:-1].split(", ")
    review["helpfulness"] = review["helpfulness"] if int(review["helpfulness"][1]) > 0 else None
    review["rating"] = "{} / 5".format(overall)
    review["reviewText"] = reviewText
    review["reviewer"] = reviewerName
    review["summary"] = summary
    review["timestamp"] = datetime.datetime.utcfromtimestamp(unixReviewTime).strftime('%B %m, %Y')
    book = find_book(asin, lenient=True)
    return book, review

def find_book(asin, lenient=False):
    result = next(mongodb.find({ "asin" : asin }), None)
    if result is None:
        if not lenient:
            return None
        else:
            result = {}
    book = {"asin": asin}
    book["title"] = result.get("title") or asin
    book["description"] = result.get("description") or "Description not available"
    book["imUrl"] = result.get("imUrl") or "https://images-na.ssl-images-amazon.com/images/I/61Ww4abGclL._AC_SX425_.jpg"
    book["categories"] = convert_flat_to_hierarchical(result.get("categories") or [])
    book["price"] = "${}".format(round_off(result["price"], 2)) if result.get("price") is not None else "Price not available"
    book["salesRank"] = "{:,}".format(result["salesRank"]) if result.get("salesRank") is not None else "Sales rank not available"
    book["related"] = result.get("related") or {}
    for key in book["related"]:
        book["related"][key] = get_titles(book["related"][key])
    book["reviews"] = sql_query("""SELECT reviewId, summary, overall FROM {MYSQL_DB}.{MYSQL_TABLE} WHERE asin = %s""".format(**app.config), (asin,))
    book["reviews"], book["rating"] = list(zip(*((item[0:2], item[2]) for item in book["reviews"]))) or [(), ()]
    book["rating"] = "{} / 5".format(round_off(average(book["rating"]), 2)) if book["rating"] else "Rating not available"
    return book

def get_titles(asins):
    if asins is None:
        return []
    else:
        query = { "asin": { "$in": asins } }
        projection = { "asin": 1, "title": 1, "_id": 0 }
        result = mongodb.find(query, projection)
        return [(book["asin"], book.get("title") or book["asin"]) for book in result]

def random_reviewId():
    count = sql_query("""SELECT MAX(reviewId) as maxId FROM {MYSQL_DB}.{MYSQL_TABLE}""".format(**app.config))[0][0]
    return random.randint(0, count)

def random_asin():
    collection = app.config["MONGO_COLLECTION"]
    count = mongodb.count()
    books = mongodb.find()
    book = next(books.skip(random.randint(0, count)))
    return book["asin"]

def get_categories():
    categories = set()
    for i in range(45):
        result = mongodb.distinct("categories.{}".format(i))
        categories = categories.union(result)
    return sorted(categories)

def get_tfidf(reviewId):
    return next(mongo.db.tf_idf.find({ "reviewId": int(reviewId) }, { "_id": 0, "tfidf": 1 }), None)

from flask import url_for, redirect, render_template
from app import app, mongo, mysql

@app.route("/random/review")
def random_review():
    cur = mysql.connection.cursor()
    cur.execute("""SELECT * FROM test.kindle_reviews LIMIT 1""")
    rv = cur.fetchall()
    return str(rv)

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
    review = None
    return render_template("review.html",
        asin = "B005G6CD5I",
        title = "Morning Rituals - How We Awaken",
        helpfulness = "0 out of 0",
        rating = "5 out of 5",
        reviewText = "This is the review text!I truly enjoyed this book. I felt so spiritual while reading this book. When I picked up this book, I never thought it would be so interesting. Loved it!! Would totally recommend it. ",
        reviewer = "Jisamariam",
        summary = "Best book ever!",
        timestamp = "October 11, 2013")

@app.route("/book/<asin>")
def get_book(asin):
    book = mongo.db.kindle_metadata.find_one_or_404({ "asin" : asin })
    return render_template("book.html",
        asin        = book["asin"],
        title       = book.get("title") or "Title",
        imUrl       = book.get("imUrl") or "https://images-na.ssl-images-amazon.com/images/I/61Ww4abGclL._AC_SX425_.jpg",
        description = book.get("description") or "Description not available",
        categories  = book.get("categories") or [],
        related     = book.get("related") or {},
        price       = "Price not available" if book.get("price") is None else f"${book['price']:.2f}",
        salesRank   = book.get("salesRank") or "Sales rank not available")

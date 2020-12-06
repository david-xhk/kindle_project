from flask import url_for, redirect, render_template, abort, request
from app import app
import app.db as db
import json
import os

@app.route("/")
def home():
    return redirect(url_for("search_book"))

@app.route("/book")
@app.route("/book/<asin>")
def get_book(asin=None):
    if asin is None:
        return redirect(url_for("search_book"))
    book = db.find_book(asin, lenient=False)
    if book is None:
        abort(404)
    return render_template("book.html", book=book)

@app.route("/add/book", methods=["GET", "POST"])
def add_book():
    if request.method == "GET":
        return render_template("add_book.html")
    else:
        book = {}
        for key in ("title", "description"):
            if key not in request.form:
                abort(400, "Missing form data.", custom=key)
            book[key] = request.form[key]
        if "imUrl" in request.form:
            book["imUrl"] = request.form["imUrl"] or "https://images-na.ssl-images-amazon.com/images/I/61Ww4abGclL._AC_SX425_.jpg"
        if "price" not in request.form:
            abort(400, "Missing form data.", custom="price")
        book["price"] = float(request.form["price"])
        new_asin = db.add_book(book)
        return redirect(url_for("get_book", asin=new_asin))

@app.route("/review")
@app.route("/review/<reviewId>")
def get_review(reviewId=None):
    if reviewId is None:
        return redirect(url_for("search_review"))
    else:
        book, review = db.find_review(reviewId)
        if review is None:
            abort(404)
        return render_template("review.html", book=book, review=review)

@app.route("/book/<asin>/review", methods=["GET", "POST"])
def add_review(asin):
    if request.method == "GET":
        book = db.find_book(asin, lenient=False)
        return render_template("add_review.html", book=book)
    else:
        review = {"asin": asin}
        for key in ("reviewText", "reviewer", "summary"):
            if key not in request.form:
                abort(400, "Missing form data.", custom=key)
            review[key] = request.form[key]
        if "rating" not in request.form:
            abort(400, "Missing form data.", custom="rating")
        review["rating"] = int(request.form["rating"])
        if review["rating"] < 0 or review["rating"] > 5:
            abort(400, "Rating out of range, must be a number from 0 to 5.", custom=review["rating"])
        reviewId = db.add_review(review)
        return redirect(url_for("get_review", reviewId=reviewId))

@app.route("/search/book", methods=["GET", "POST"])
def search_book():
    if request.method == "GET":
        return render_template("search_form.html")
    search = {}
    for key in ("title", "sort_by", "order_by"):
        search[key] = request.form.get(key)
    search["filter_by"] = request.form.getlist("filter_by")
    if search["order_by"] is not None:
        search["order_by"] = 1 if search["order_by"] == "ascending" else -1 if search["order_by"] == "descending" else None
    results = db.search_book(**search)
    if results:
        results = results[:20]
    else:
        results = "No results found."
    if request.form.get("source") == "search_form":
        return render_template("search_results.html", results=results)
    else:
        return render_template("search.html", search=search, results=results)

@app.route("/random/book")
def random_book():
    asin = db.random_asin()
    return redirect(url_for("get_book", asin=asin))

@app.route("/random/review")
def random_review():
    reviewId = db.random_reviewId()
    return redirect(url_for("get_review", reviewId=reviewId))

@app.route("/categories")
def get_categories():
    if not os.path.exists("app/static/categories.json"):
        categories = db.get_categories()
        with open("app/static/categories.json", "w") as file:
            json.dump(categories, file)
    return redirect("/static/categories.json")

@app.route("/tfidf/<reviewId>")
def get_tfidf(reviewId):
    result = db.get_tfidf(reviewId)
    if result is None:
        abort(404)
    return result["tfidf"]

@app.route("/pearson")
def get_pearson():
    return redirect("/static/pearson/coef.txt")

@app.route("/pearson/data")
def get_pearson_data():
    return redirect("/static/pearson/data.json")

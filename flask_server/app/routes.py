from flask import url_for, redirect, render_template, abort
from app import app
from app.db import find_book, find_review, random_asin, random_reviewId

@app.route("/book/<asin>")
def get_book(asin):
    book = find_book(asin, lenient=False)
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
    asin = random_asin()
    return redirect(url_for("get_book", asin=asin))

@app.route("/random/review")
def random_review():
    reviewId = random_reviewId()
    return redirect(url_for("get_review", reviewId=reviewId))

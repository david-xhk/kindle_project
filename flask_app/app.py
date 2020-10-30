from flask import Flask, url_for, redirect, render_template
from config import Config
from flask_pymongo import PyMongo

app = Flask(__name__)
app.config.from_object(Config)
mongo = PyMongo(app)

@app.route("/random/book")
def hello_world():
    book = next(mongo.db.kindle_metadata.aggregate([{ "$sample" : { "size": 1 } }]))
    asin = book["asin"]
    return redirect(url_for("get_book", asin=asin))

@app.route("/book/<asin>")
def get_book(asin):
    book = mongo.db.kindle_metadata.find_one_or_404({ "asin" : asin })
    return render_book(book)

def render_book(book):
    related = book.get("related") or {}
    return render_template("book.html",
        asin              = book["asin"],
        title             = book.get("title", "Untitled"),
        imUrl             = book.get("imUrl", "https://images-na.ssl-images-amazon.com/images/I/61Ww4abGclL._AC_SX425_.jpg"),
        description       = book.get("description", "Description not available"),
        categories        = book.get("categories", []),
        also_viewed       = related.get("also_viewed"),
        also_bought       = related.get("also_bought"),
        buy_after_viewing = related.get("buy_after_viewing"),
        price             = book.get("price", "Price not available"),
        salesRank         = book.get("salesRank", "Sales rank not available"))

if __name__ == "__main__":
    app.run(host="0.0.0.0")
from flask import Flask
from config import Config
from flask_pymongo import PyMongo

app = Flask(__name__)
app.config.from_object(Config)
mongo = PyMongo(app)

@app.route("/")
def hello_world():
    book = next(mongo.db.kindle_metadata.aggregate([{ "$sample" : { "size": 1 } }]))
    asin = book["asin"]
    title = book.get("title", "Untitled")
    imUrl = book.get("imUrl", "https://images-na.ssl-images-amazon.com/images/I/61Ww4abGclL._AC_SX425_.jpg")
    description = book.get("description", "No description available")

    return f"""\
<html>
    <h1>{title}</h1>
    <img src="{imUrl}" alt="{title}" />
    <br />
    <h2>Description</h2>
    <p>{description}</p>
    <span><b>ASIN:</b> {asin}</span>
</html>"""

if __name__ == "__main__":
    app.run(host="0.0.0.0")
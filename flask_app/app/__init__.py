from flask import Flask
from .config import Config
from flask_pymongo import PyMongo
from flask_mysqldb import MySQL

app = Flask(__name__)
app.config.from_object(Config)
mongo = PyMongo(app)
mysql = MySQL(app)

from app import routes
from flask import Flask
from .config import Config
from flask_pymongo import PyMongo
from flask_mysqldb import MySQL

__version__ = 1.0

app = Flask(__name__)
app.config.from_object(Config)
mongo = PyMongo(app)
mysql = MySQL(app)

from app import routes

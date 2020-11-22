from flask import Flask
from .config import Config
from flask_mysqldb import MySQL
from flask_pymongo import PyMongo

__version__ = 1.2

app = Flask(__name__)
app.config.from_object(Config)
mysql = MySQL(app)
mongo = PyMongo(app)

from app import db
from app import routes

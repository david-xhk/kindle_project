from app import app
from flask import request
from log4mongo.handlers import MongoFormatter, BufferedMongoHandler
import logging
import datetime

def initialize_access_logger(app):
    class AccessRecordFormatter(logging.Formatter):
        def format(self, record):
            remote_address, method, path, status = record.args
            document = {
                "timestamp": datetime.datetime.utcnow(),
                "remote_address": remote_address,
                "method": method,
                "path": path,
                "status": status
            }
            return document
    
    access_handler = BufferedMongoHandler(
        host=app.config["MONGO_HOST"],
        port=app.config["MONGO_PORT"],
        database_name=app.config["MONGO_DB"],
        collection="access_log",
        username=app.config["MONGO_USER"],
        password=app.config["MONGO_PASSWORD"],
        authentication_db=app.config["MONGO_DB"],
        formatter=AccessRecordFormatter(),
        buffer_size=100,
        buffer_periodical_flush_timing=10.0,
        buffer_early_flush_level=logging.CRITICAL,
    )

    access_logger = logging.getLogger("flask.app.access")
    access_logger.setLevel(logging.INFO)
    access_logger.addHandler(access_handler)

    @app.after_request
    def after_request(response):
        logger = logging.getLogger("flask.app.access")
        logger.info("", request.remote_addr, request.method, request.path, response.status)
        return response

initialize_access_logger(app)

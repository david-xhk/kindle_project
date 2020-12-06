import os

class Config:
    MYSQL_HOST = os.environ.get("MYSQL_PRIVATE_IPV4") or "10.12.192.169"
    MYSQL_PORT = int(os.environ.get("MYSQL_PORT") or 3306)
    MYSQL_DB = os.environ.get("MYSQL_DB") or "project"
    MYSQL_TABLE = os.environ.get("MYSQL_TABLE") or "kindle_reviews"
    MYSQL_USER = os.environ.get("MYSQL_USER") or "root"
    MYSQL_PASSWORD = os.environ.get("MYSQL_PASSWORD") or "password"
    
    MONGO_HOST = os.environ.get("MONGO_PRIVATE_IPV4") or "10.12.192.169"
    MONGO_PORT = int(os.environ.get("MONGO_PORT") or 27017)
    MONGO_DB = os.environ.get("MONGO_DB") or "project"
    MONGO_COLLECTION = os.environ.get("MONGO_COLLECTION") or "kindle_metadata"
    MONGO_USER = os.environ.get("MONGO_USER") or "root"
    MONGO_PASSWORD = os.environ.get("MONGO_PASSWORD") or "password"

    MONGO_URI = "mongodb://{user}:{password}@{host}:{port}/{db}?authSource={db}&readPreference=primary&ssl=false".format(
        host     = MONGO_HOST,
        port     = MONGO_PORT,
        db       = MONGO_DB,
        user     = MONGO_USER,
        password = MONGO_PASSWORD
    )

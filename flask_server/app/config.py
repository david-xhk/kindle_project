import os

class Config:
    MYSQL_HOST = os.environ.get("MYSQL_HOST") or "127.0.0.1"
    MYSQL_PORT = int(os.environ.get("MYSQL_PORT")) or 3306
    MYSQL_DB = os.environ.get("MYSQL_DB") or "project"
    MYSQL_USER = os.environ.get("MYSQL_USER") or "root"
    MYSQL_PASSWORD = os.environ.get("MYSQL_PASSWORD") or "password"
    
    MONGO_URI = "mongodb://{user}:{password}@{host}:{port}/{db}?authSource={db}&readPreference=primary&ssl=false".format(
        host     = os.environ.get("MONGO_HOST") or "127.0.0.1",
        port     = os.environ.get("MONGO_PORT") or 27017,
        db       = os.environ.get("MONGO_DB") or "project",
        user     = os.environ.get("MONGO_USER") or "root",
        password = os.environ.get("MONGO_PASSWORD") or "password"
    )

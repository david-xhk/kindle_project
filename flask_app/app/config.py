import getpass

class Config:
    MYSQL_HOST = input("MySQL host: ") or "127.0.0.1",
    MYSQL_PORT = input("MySQL port: ") or 3306
    MYSQL_DB = input("MySQL database: ") or "project"
    MYSQL_USER = input("MySQL user: ") or "root"
    MYSQL_PASSWORD = getpass.getpass("MySQL password: ") or "password"
    
    MONGO_URI = "mongodb://{user}:{password}@{host}:{port}/{db}?authSource=admin&readPreference=primary&ssl=false".format(
        host     = input("MongoDB host: ") "127.0.0.1",
        port     = input("MongoDB port: ") or 27017,
        db       = input("MongoDB database: ") or "project",
        user     = input("MongoDB user: ") or "root",
        password = getpass.getpass("MongoDB password: ") or "password"
    )

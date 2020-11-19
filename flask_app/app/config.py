import getpass

class Config:
    MYSQL_HOST = input("Enter MySQL host: ") or "127.0.0.1",
    MYSQL_PORT = input("Enter MySQL port: ") or 3306
    MYSQL_DB = input("Enter MySQL database: ") or "project"
    MYSQL_USER = input("Enter MySQL user: ") or "root"
    MYSQL_PASSWORD = getpass.getpass("Enter MySQL password: ") or "password"
    
    MONGO_URI = "mongodb://{user}:{password}@{host}:{port}/{db}?authSource=admin&readPreference=primary&ssl=false".format(
        host     = input("Enter MongoDB host: ") "127.0.0.1",
        port     = input("Enter MongoDB port: ") or 27017,
        db       = input("Enter MongoDB database: ") or "project",
        user     = input("Enter MongoDB user: ") or "root",
        password = getpass.getpass("Enter MongoDB password: ") or "password"
    )

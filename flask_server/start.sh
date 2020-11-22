#!/bin/bash

# Start the flask server
echo "Starting flask server..."
if [ -z "$MYSQL_HOST" ]
then
    echo "Enter MySQL host address:"
    read -s MYSQL_HOST
fi
if [ -z "$MYSQL_PORT" ]
then
    echo "Enter MySQL port number:"
    read -s MYSQL_PORT
fi
if [ -z "$MYSQL_DB" ]
then
    echo "Enter MySQL database name:"
    read -s MYSQL_DB
fi
if [ -z "$MYSQL_USER" ]
then
    echo "Enter name of MySQL database user:"
    read -s MYSQL_USER
fi
if [ -z "$MYSQL_PASSWORD" ]
then
    echo "Enter password for MySQL database user:"
    read -s MYSQL_PASSWORD
fi
if [ -z "$MONGO_HOST" ]
then
    echo "Enter MongoDB host address:"
    read -s MONGO_HOST
fi
if [ -z "$MONGO_PORT" ]
then
    echo "Enter MongoDB port number:"
    read -s MONGO_PORT
fi
if [ -z "$MONGO_DB" ]
then
    echo "Enter MongoDB database name:"
    read -s MONGO_DB
fi
if [ -z "$MONGO_USER" ]
then
    echo "Enter name of MongoDB database user:"
    read -s MONGO_USER
fi
if [ -z "$MONGO_PASSWORD" ]
then
    echo "Enter password for MongoDB database user:"
    read -s MONGO_PASSWORD
fi
# Run the server in the background with no hangup and pipe all outputs to output.log
sudo -E nohup python3 -u run.py >> output.log 2>&1 &
echo "Started flask server"

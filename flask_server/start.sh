#!/bin/bash

# Load Flask configuration
echo 'Loading Flask configuration'
source config

if [ -z "$MYSQL_PRIVATE_IPV4" ]
then
    echo 'Enter MySQL private IPv4 address:'
    read MYSQL_PRIVATE_IPV4
fi
if [ -z "$MYSQL_PORT" ]
then
    echo 'Enter MySQL port number:'
    read MYSQL_PORT
fi
if [ -z "$MYSQL_DB" ]
then
    echo 'Enter MySQL database name:'
    read MYSQL_DB
fi
if [ -z "$MYSQL_USER" ]
then
    echo 'Enter name of MySQL database user:'
    read MYSQL_USER
fi
if [ -z "$MYSQL_PASSWORD" ]
then
    echo 'Enter password for MySQL database user:'
    read MYSQL_PASSWORD
fi
if [ -z "$MONGO_PRIVATE_IPV4" ]
then
    echo 'Enter MongoDB private IPv4 address:'
    read MONGO_PRIVATE_IPV4
fi
if [ -z "$MONGO_PORT" ]
then
    echo 'Enter MongoDB port number:'
    read MONGO_PORT
fi
if [ -z "$MONGO_DB" ]
then
    echo 'Enter MongoDB database name:'
    read MONGO_DB
fi
if [ -z "$MONGO_USER" ]
then
    echo 'Enter name of MongoDB database user:'
    read MONGO_USER
fi
if [ -z "$MONGO_PASSWORD" ]
then
    echo 'Enter password for MongoDB database user:'
    read MONGO_PASSWORD
fi

# Run the server in the background with no hangup and pipe all outputs to output.log
echo 'Starting Flask server'
sudo -E nohup python3 -u run.py >> output.log 2>&1 &

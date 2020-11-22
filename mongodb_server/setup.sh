#!/bin/bash

# Install MongoDB
echo "Installing MongoDB..."
# Import the public key used by the package management system
wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
# Create a list file for MongoDB
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
# Update system and reload local package database
sudo apt-get -q update
# Install the MongoDB packages
sudo apt-get -q -y install mongodb-org
echo "Installed MongoDB"

# Start MongoDB service
echo "Starting MongoDB service..."
sudo service mongod start
echo "Started MongoDB service"

# Wait for MongoDB service to be ready to accept connections
echo "Waiting for MongoDB service to be ready..."
until mongo --quiet --eval "print(\"Connect succeeded\")"
do
    echo "."
    sleep 1
done
echo "MongoDB service is ready"

# Create root user
echo "Creating root user..."
if [ -z "$MONGO_ROOT_PASS" ]
then
    echo "Enter MongoDB root password:"
    read -s MONGO_ROOT_PASS
fi
mongo << EOF
use admin;
db.createUser({
    user: "root",
    pwd: "$MONGO_ROOT_PASS",
    roles: [ "root" ]
})
EOF
echo "Created root user"

# Create user
echo "Creating user..."
if [ -z "$MONGO_DB" ]
then
    echo "Enter MongoDB database name:"
    read MONGO_DB
fi
if [ -z "$MONGO_USER" ]
then
    echo "Enter name of MongoDB database user:"
    read MONGO_USER
fi
if [ -z "$MONGO_PASSWORD" ]
then
    echo "Enter password for MongoDB database user:"
    read -s MONGO_PASSWORD
fi
mongo << EOF
use admin;
db.auth({
    user: "root",
    pwd: "$MONGO_ROOT_PASS",
})
use $MONGO_DB;
db.createUser({
    user: "$MONGO_USER",
    pwd: "$MONGO_PASSWORD",
    roles: [ { role: "userAdmin", db: "$MONGO_DB" },
             { role: "dbAdmin",   db: "$MONGO_DB" },
             { role: "readWrite", db: "$MONGO_DB" }
           ]
});
EOF
echo "Created user"

# Download kindle_metadata.json
echo "Downloading kindle_metadata.json..."
if [ -z "$PROD_IP" ]
then
    echo "Enter IP address of production server:"
    read PROD_IP
fi
wget -q "$PROD_IP/kindle_metadata.json"
echo "Downloaded kindle_metadata.json"

# Load kindle_metadata.json
echo "Loading kindle_metadata.json..."
mongoimport -u root -p $MONGO_ROOT_PASS -d $MONGO_DB -c kindle_metadata --authenticationDatabase admin --file kindle_metadata.json
rm kindle_metadata.json
echo "Loaded kindle_metadata.json"

# Configure MongoDB
echo "Configuring MongoDB..."
# Uncomment security line
sudo sed -i "s/^#security:/security:/g" /etc/mongod.conf
# Insert 'authorization: enabled' after security line
sudo sed -i "/^security:/a \  authorization: enabled" /etc/mongod.conf
if [ -z "$MONGO_BIND_ADDR" ]
then
    echo "Enter MongoDB bind address:"
    read MONGO_BIND_ADDR
fi
# Update bind address
sudo sed -i "s/bindIp:.*/bindIp: $MONGO_BIND_ADDR/g" /etc/mongod.conf
# Print mongod.conf for verification
cat /etc/mongod.conf
echo "Configured MongoDB"

# Restart MongoDB service
echo "Restarting MongoDB service..."
sudo service mongod restart
echo "Restarted MongoDB service"

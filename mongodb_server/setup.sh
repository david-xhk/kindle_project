#!/bin/bash

echo "Setting up MongoDB server..."

# Install MongoDB
echo "Installing MongoDB..."
# Import the public key used by the package management system
wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add - >/dev/null
# Create a list file for MongoDB
sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list << EOF >/dev/null
deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.4 multiverse
EOF
# Update system and reload local package database
sudo apt-get update -qq >/dev/null
# Install the MongoDB packages
sudo DEBIAN_FRONTEND=noninteractive apt-get install mongodb-org -qq >/dev/null
echo "Installed MongoDB"

# Start MongoDB service
echo "Starting MongoDB service..."
sudo service mongod start
echo "Started MongoDB service"

# Wait for MongoDB service to be ready to accept connections
echo "Waiting for MongoDB service to be ready..."
until mongo --quiet --eval "print(\"Connect succeeded\")" 2>&1 >/dev/null
do
    sleep 1
done
echo "MongoDB service is ready"

# Create MongoDB root user
echo "Creating MongoDB root user..."
if [ -z "$MONGO_ROOT_PASSWORD" ]
then
    echo "Enter MongoDB root password:"
    read -s MONGO_ROOT_PASSWORD
fi
read -d '' cmd << EOF
use admin;
db.createUser({
    user: "root",
    pwd: "$MONGO_ROOT_PASSWORD",
    roles: [ "root" ]
});
EOF
echo "Executing MongoDB command:"
echo "$cmd" | sed 's/^/  /'
echo "$cmd" | mongo --quiet
echo "Created MongoDB root user"

# Create MongoDB database user
echo "Creating MongoDB database user..."
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
read -d '' cmd << EOF
use admin;
db.auth({
    user: "root",
    pwd: "$MONGO_ROOT_PASSWORD",
});
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
echo "Executing MongoDB command:"
echo "$cmd" | sed 's/^/  /'
echo "$cmd" | mongo --quiet
echo "Created MongoDB database user"

# Download MongoDB database source file
echo "Downloading MongoDB database source file..."
if [ -z "$PRODUCTION_HOST" ]
then
    echo "Enter IP address of production server:"
    read PRODUCTION_HOST
fi
if [ -z "$MONGO_SOURCE" ]
then
    echo "Enter name of MongoDB database source file:"
    read MONGO_SOURCE
fi
wget -q "$PRODUCTION_HOST/$MONGO_SOURCE"
echo "Downloaded MongoDB database source file"

# Load MongoDB database source file
echo "Loading MongoDB database source file..."
if [ -z "$MONGO_COLLECTION" ]
then
    echo "Enter name of MongoDB database collection:"
    read MONGO_COLLECTION
fi
mongoimport -u root -p $MONGO_ROOT_PASSWORD -d $MONGO_DB -c $MONGO_COLLECTION --authenticationDatabase admin --file $MONGO_SOURCE
rm $MONGO_SOURCE
echo "Loaded MongoDB database source file"

# Configure MongoDB
echo "Configuring MongoDB..."
# Uncomment security line
sudo sed -i "s/^#security:/security:/g" /etc/mongod.conf
# Insert 'authorization: enabled' after security line
sudo sed -i "/^security:/a \  authorization: enabled" /etc/mongod.conf
if [ -z "$MONGO_BIND_ADDRESS" ]
then
    echo "Enter MongoDB bind address:"
    read MONGO_BIND_ADDRESS
fi
# Update bind address
sudo sed -i "s/bindIp:.*/bindIp: $MONGO_BIND_ADDRESS/g" /etc/mongod.conf
# Print mongod.conf for verification
echo "MongoDB config file:"
cat /etc/mongod.conf | sed 's/^/  /'
echo "Configured MongoDB"

# Restart MongoDB service
echo "Restarting MongoDB service..."
sudo service mongod restart
echo "Restarted MongoDB service"

echo "Finished setting up MongoDB server"

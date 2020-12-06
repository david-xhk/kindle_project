#!/bin/bash

# Log function for debugging purposes
log() {
    # Read input from arguments or stdin
    if [ -z "$1" ]; then read -d '' input; else input="$1"; fi
    # Indent input by 2 spaces
    echo "$input" | sed 's/^/  /'
}

# Command to run MongoDB shell
mongo_shell='mongo --quiet'

# Function to execute MongoDB commands
execute() {
    # Read command from arguments or stdin
    if [ -z "$1" ]; then read -d '' cmd; else cmd="$1"; fi
    echo 'Executing MongoDB command:'
    log "$cmd"
    # Pipe command into MongoDB shell
    echo "$cmd" | $mongo_shell
}

echo 'Setting up MongoDB server'

# Install MongoDB
echo 'Installing MongoDB'
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

# Start MongoDB service
echo 'Starting MongoDB service'
sudo service mongod start

# Wait for MongoDB service to be ready to accept connections
echo 'Waiting for MongoDB service to be ready...'
until mongo --quiet --eval 'print("Connect succeeded")' 2>&1 >/dev/null
do
    sleep 1
done

# Create MongoDB root user
if [ -z "$MONGO_ROOT_PASSWORD" ]
then
    echo 'Enter MongoDB root password:'
    read MONGO_ROOT_PASSWORD
fi
echo 'Creating MongoDB root user'
execute << EOF
use admin;
db.createUser({
    user: "root",
    pwd: "$MONGO_ROOT_PASSWORD",
    roles: [ "root" ]
});
EOF

# Create MongoDB database user
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
echo 'Creating MongoDB database user'
execute << EOF
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

# Load MongoDB database source file
if [ -z "$MONGO_SOURCE" ]
then
    echo 'Enter name of MongoDB database source file:'
    read MONGO_SOURCE
fi
if [ -z "$MONGO_COLLECTION" ]
then
    echo 'Enter name of MongoDB database collection:'
    read MONGO_COLLECTION
fi
echo 'Loading MongoDB database source file'
mongoimport -u root -p "$MONGO_ROOT_PASSWORD" -d "$MONGO_DB" -c "$MONGO_COLLECTION" --authenticationDatabase admin --file "$MONGO_SOURCE"
rm "$MONGO_SOURCE"

# Create indexes
echo 'Creating MongoDB indexes'
execute << EOF
use admin;
db.auth({
    user: "root",
    pwd: "$MONGO_ROOT_PASSWORD",
});
use $MONGO_DB;
db.$MONGO_COLLECTION.createIndex({ "asin": 1 }, { unique: true });
db.$MONGO_COLLECTION.createIndex({ "price": -1 });
db.$MONGO_COLLECTION.createIndex({ "categories": 1 });
db.$MONGO_COLLECTION.createIndex({ "title": "text" });
EOF

# Configure MongoDB
if [ -z "$MONGO_BIND_ADDRESS" ]
then
    echo 'Enter MongoDB bind address:'
    read MONGO_BIND_ADDRESS
fi
echo 'Configuring MongoDB...'
# Uncomment security line
sudo sed -i "s/^#security:/security:/g" /etc/mongod.conf
# Insert 'authorization: enabled' after security line
sudo sed -i "/^security:/a \  authorization: enabled" /etc/mongod.conf
# Update bind address
sudo sed -i "s/bindIp:.*/bindIp: $MONGO_BIND_ADDRESS/g" /etc/mongod.conf
# Print mongod.conf for verification
echo 'MongoDB config file:'
cat /etc/mongod.conf | log

# Restart MongoDB service
echo 'Restarting MongoDB service'
sudo service mongod restart

# Save MongoDB configuration
echo 'Saving MongoDB configuration'
cat << EOF >> config
export MONGO_ROOT_PASSWORD=$MONGO_ROOT_PASSWORD;
export MONGO_DB=$MONGO_DB;
export MONGO_COLLECTION=$MONGO_COLLECTION;
EOF

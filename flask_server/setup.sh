#!/bin/bash

echo 'Setting up Flask server'

# Install Flask dependencies
echo 'Installing Flask dependencies'
sudo apt-get update -qq >/dev/null
sudo DEBIAN_FRONTEND=noninteractive apt-get install python3-pip unzip libmysqlclient-dev -qq >/dev/null

# Install more Flask dependencies
echo 'Installing more Flask dependencies'
pip3 install -q -r requirements.txt

# Save Flask configuration
echo 'Saving Flask configuration'
cat << EOF >> config
export MYSQL_PRIVATE_IPV4=$MYSQL_PRIVATE_IPV4;
export MYSQL_PORT=$MYSQL_PORT;
export MYSQL_DB=$MYSQL_DB;
export MYSQL_USER=$MYSQL_USER;
export MYSQL_PASSWORD=$MYSQL_PASSWORD;
export MONGO_PRIVATE_IPV4=$MONGO_PRIVATE_IPV4;
export MONGO_PORT=$MONGO_PORT;
export MONGO_DB=$MONGO_DB;
export MONGO_USER=$MONGO_USER;
export MONGO_PASSWORD=$MONGO_PASSWORD;
EOF

# Start Flask server
./start.sh

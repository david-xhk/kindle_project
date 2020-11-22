#!/bin/bash

echo "Setting up Flask server..."

# Install Flask dependencies
echo "Installing Flask dependencies..."
sudo apt-get update -qq >/dev/null
sudo DEBIAN_FRONTEND=noninteractive apt-get install python3-pip unzip libmysqlclient-dev -qq >/dev/null
echo "Installed Flask dependencies"

# Download Flask server source file
echo "Downloading Flask server source file..."
if [ -z "$PRODUCTION_HOST" ]
then
    echo "Enter IP address of production server:"
    read PRODUCTION_HOST
fi
if [ -z "$FLASK_SOURCE" ]
then
    echo "Enter name of Flask server source file:"
    read FLASK_SOURCE
fi
wget -q "$PRODUCTION_HOST/$FLASK_SOURCE"
echo "Downloaded Flask server source file"

# Installing Flask server source file
echo "Installing Flask server source file..."
unzip -q $FLASK_SOURCE -d temp
mv temp/*/* .
rm -r temp $FLASK_SOURCE setup.sh
chmod u+x *.sh
echo "Installed Flask server source file"

# Install more Flask dependencies
echo "Installing more Flask dependencies..."
pip3 install -q -r requirements.txt
echo "Installed more Flask dependencies"

echo "Finished setting up Flask server"

# Start Flask server
./start.sh

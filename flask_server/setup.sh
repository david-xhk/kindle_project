#!/bin/bash

echo "Setting up Flask server..."

# Install Flask dependencies
echo "Installing Flask dependencies..."
sudo apt-get update -qq >/dev/null
sudo DEBIAN_FRONTEND=noninteractive apt-get install python3-pip unzip libmysqlclient-dev -qq >/dev/null
echo "Installed Flask dependencies"

# Download Flask server source file
echo "Downloading Flask source file..."
if [ -z "$PROD_IP" ]
then
    echo "Enter IP address of production server:"
    read PROD_IP
fi
if [ -z "$FLASK_FILE" ]
then
    echo "Enter name of Flask server source file:"
    read FLASK_FILE
fi
wget -q "$PROD_IP/$FLASK_FILE"
echo "Downloaded Flask server source file"

# Installing Flask server source file
echo "Installing Flask server source file..."
unzip -q $FLASK_FILE -d temp
mv temp/*/* .
rm -r temp $FLASK_FILE setup.sh
chmod u+x *.sh
echo "Installed Flask server source file"

# Install more Flask dependencies
echo "Installing more Flask dependencies..."
pip3 install -q -r requirements.txt
echo "Installed more Flask dependencies"

echo "Finished setting up Flask server"

# Start Flask server
./start.sh

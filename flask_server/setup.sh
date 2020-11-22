#!/bin/bash

# Install dependencies
echo "Installing dependencies..."
sudo apt-get -q update
sudo apt-get -q -y install python3-pip unzip libmysqlclient-dev
echo "Installed dependencies"

# Download flask_server.zip
echo "Downloading flask_server.zip..."
if [ -z "$PROD_IP" ]
then
    echo "Enter IP address of production server:"
    read PROD_IP
fi
wget -q "$PROD_IP/flask_server.zip"
echo "Downloaded flask_server.zip"

# Installing flask_server
echo "Installing flask_server..."
unzip flask_server.zip
chmod u+x flask_server/*.sh
mv flask_server/* .
rm -r flask_server flask_server.zip setup.sh
echo "Installed flask_server"

# Install requirements
echo "Installing requirements..."
pip3 install -q -r requirements.txt
echo "Installed requirements"

#!/bin/bash

# Load config file
if [ -z "$CONFIG_DONE" ]; then
    echo "Loading config file..."
    source config
    echo "Loaded config file"
    echo
fi

# Deploy production server
./deploy.sh production_server

# Setup MySQL server
./setup.sh mysql_server

# Setup MongoDB server
./setup.sh mongodb_server

# Setup Flask server
./setup.sh flask_server

# Start Flask server
./connect.sh flask_server ./start.sh

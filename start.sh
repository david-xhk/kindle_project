#!/bin/bash

# Load config file
. load_config.sh

# Deploy production server
##./deploy.sh production_server &&

# Setup MySQL server
./setup.sh mysql_server &&

# Setup MongoDB server
./setup.sh mongodb_server &&

# Setup Flask server
./setup.sh flask_server &&

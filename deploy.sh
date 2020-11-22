#!/bin/bash

# Load config file
source load_config.sh

# Copy file to server
./copy.sh $1 "${2:-*}" &&

# Start server
./connect.sh $1 ./start.sh

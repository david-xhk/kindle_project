#!/bin/bash

# Load config file
if [ -z "$CONFIG_DONE" ]; then
    echo "Loading config file..."
    source config
    echo "Loaded config file"
    echo
fi

# File to copy
FILE=${2:-'*'}

# Stop server and remove file
./connect.sh $1 "bash -c 'if [ -f stop.sh ]; then ./stop.sh && sleep 5; fi; rm -rf $FILE;'" &&

# Copy file to server
./copy.sh $1 "$FILE" &&

# Restart server
./connect.sh $1 ./start.sh

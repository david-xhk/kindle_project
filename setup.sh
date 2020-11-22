#!/bin/bash

# Load config file
if [ -z "$CONFIG_DONE" ]; then
    echo "Loading config file..."
    source config
    echo "Loaded config file"
    echo
fi

# Copy setup.sh to server
./copy.sh $1 setup.sh

# Setup server
./connect.sh $1 ./setup.sh

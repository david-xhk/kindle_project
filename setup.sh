#!/bin/bash

# Load config file
source load_config.sh

# Copy setup.sh to server
./copy.sh $1 setup.sh &&

# Setup server
./connect.sh $1 ./setup.sh

#!/bin/bash

# Load config file
source load_config.sh

# Stop server and remove file
./connect.sh $1 "bash -c 'if [ -f stop.sh ]; then ./stop.sh && sleep 5; fi; rm -rf ${2:-'*'};'" &&

# Redeploy server
./deploy.sh "$@"

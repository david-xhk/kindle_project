#!/bin/bash

cd root

# Start the server on port 80 in the background with no hangup and pipe all outputs to output.log
echo "Starting production server..."
sudo nohup python3 -u -m http.server 80 >> ../output.log 2>&1 &
echo "Started production server"

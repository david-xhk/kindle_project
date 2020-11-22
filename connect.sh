#!/bin/bash

# Load config file
if [ -z "$CONFIG_DONE" ]; then
    echo "Loading config file..."
    source config
    echo "Loaded config file"
    echo
fi

# Remote host
HOST="ubuntu@${!1}"

# Start bash shell if no command was provided in second argument
if [ -z "$2" ]; then
    echo "Connecting to $HOST..."
    ssh -i ec2-key.pem -o "StrictHostKeyChecking no" -o "ConnectionAttempts 20" -t $HOST "$(<config) sudo -E bash -l"
    STATUS=$?
    echo "Connection ended with exit status $STATUS"

# Execute the provided command
else
    echo "Executing '$2' in $HOST..."
    ssh -i ec2-key.pem -o "StrictHostKeyChecking no" -o "ConnectionAttempts 20" $HOST "$(<config) sudo -E $2"
    STATUS=$?
    if [ $STATUS -eq 0 ]; then
        echo "Executed '$2' in $HOST"
    fi
fi

echo
exit $STATUS

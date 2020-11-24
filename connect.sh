#!/bin/bash

# Load config file
source load_config.sh

# Remote host
host="ubuntu@${!1}"

# Check second argument for command
if [ -z "$2" ]
then
    # Start bash shell if no command provided
    echo "Connecting to $host..."
    ssh $SSH_OPTIONS -t $host "$(<config) sudo -E bash -l"
    exit_status=$?
    message="Connection ended with exit status $exit_status"
else
    # Execute provided command
    echo "Executing '$2' in $host..."
    ssh $SSH_OPTIONS $host "$(<config) sudo -E $2"
    exit_status=$?
    if [ $exit_status -eq 0 ]
    then
        message="Executed '$2' in $host"
    else
        message="Failed to execute '$2' in $host"
    fi
fi

# Print message and exit
echo "$message"
echo
exit $exit_status

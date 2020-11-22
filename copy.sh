#!/bin/bash

# Load config file
. load_config.sh

# Where to copy from and to
where=${3:-there}
if [ "$where" == there ]
then
    # Copy from local directory to remote home directory
    from="$1/$2"
    to="ubuntu@${!1}:~"
elif [ "$where" == here ]
then
    # Copy from remote directory to local directory
    from="ubuntu@${!1}:$2"
    to="$1"
else
    echo "arg 3 ('$3') must be either 'here' or 'there'"
    exit 1
fi

# Key file
if [ -z "$DEV_KEY_FILE" ]
then
    echo "Enter name of key file:"
    read DEV_KEY_FILE
fi

# Copy files
echo "Copying $from to $to..."
scp -i "$DEV_KEY_FILE"  -o "StrictHostKeyChecking no" -o "ConnectionAttempts 20" -r $from $to
exit_status=$?
if [ $exit_status -ne 0 ]
then
    message="Failed to copy $from to $to"
else
    message="Copied $from to $to"
fi

# Print message and exit
echo "$message"
echo
exit $exit_status

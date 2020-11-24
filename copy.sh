#!/bin/bash

# Load config file
source load_config.sh

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

# Copy files
echo "Copying $from to $to..."
scp $SSH_OPTIONS -r $from $to
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

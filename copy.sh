#!/bin/bash

# Load config file
if [ -z "$CONFIG_DONE" ]; then
    echo "Loading config file..."
    source config
    echo "Loaded config file"
    echo
fi

# Where to copy from and to
WHERE=${3:-there}
if [ "$WHERE" == there ]; then
    FROM="$1/$2"
    TO="ubuntu@${!1}:~"

elif [ "$WHERE" == here ]; then
    FROM="ubuntu@${!1}:$2"
    TO="$1"

else
    echo "WHERE (arg3) must be either 'here' or 'there'"
    exit 1
fi

# Copy files
echo "Copying $FROM to $TO..."
scp -i ec2-key.pem  -o "StrictHostKeyChecking no" -o "ConnectionAttempts 20" -r $FROM $TO

# Print status
STATUS=$?
if [ $STATUS -ne 0 ]; then
    echo "Failed to copy $FROM to $TO"
else
    echo "Copied $FROM to $TO"
fi

echo
exit $STATUS

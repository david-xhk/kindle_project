#!/bin/bash

# Load MongoDB configuration
echo 'Loading MongoDB configuration'
source config

# Log function for debugging purposes
log() {
    # Read input from arguments or stdin
    if [ -z "$1" ]; then read -d '' input; else input="$1"; fi
    # Indent input by 2 spaces
    echo "$input" | sed 's/^/  /'
}

# Command to run MongoDB shell
mongo_shell='mongo --quiet'

# Function to execute MongoDB commands
execute() {
    # Read command from arguments or stdin
    if [ -z "$1" ]; then read -d '' cmd; else cmd="$1"; fi
    echo 'Executing MongoDB command:'
    log "$cmd"
    # Pipe command into MongoDB shell
    echo "$cmd" | $mongo_shell
}

# Import tf-idf results
echo 'Importing tf-idf results'
mongoimport -u root -p "$MONGO_ROOT_PASSWORD" -d "$MONGO_DB" -c tf_idf --authenticationDatabase admin --file "tf_idf.json"
rm "tf_idf.json"

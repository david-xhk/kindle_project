#!/bin/bash

# Output path
OUTFILE="$1"

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

# Remove file if it exists
if [ -e "$OUTFILE" ]
then
    rm "$OUTFILE"
fi

# Export prices
echo 'Exporting prices'
execute << EOF > "$OUTFILE"
use admin;
db.auth({
    user: "root",
    pwd: "$MONGO_ROOT_PASSWORD",
});
use $MONGO_DB;
db.$MONGO_COLLECTION.find({
    price: {
        \$exists: 1,
        \$ne: null,
    },
}, {
    _id: 0,
    asin: 1,
    price: 1,
}).forEach(function(doc) {
    print('"' + doc.asin + '",' + doc.price)
})
EOF

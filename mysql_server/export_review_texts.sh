#!/bin/bash

# Output path
OUTFILE="$1"

# Load MySQL configuration
echo 'Loading MySQL configuration'
source config

# Log function for debugging purposes
log() {
    # Read input from arguments or stdin
    if [ -z "$1" ]; then read -d '' input; else input="$1"; fi
    # Indent input by 2 spaces
    echo "$input" | sed 's/^/  /'
}

# Command to run MySQL shell (with root password authorization)
mysql_shell="mysql -u root -h localhost -p$MYSQL_ROOT_PASSWORD"

# Function to execute MySQL commands
execute() {
    # Read command from arguments or stdin
    if [ -z "$1" ]; then read -d '' cmd; else cmd="$1"; fi
    echo 'Executing MySQL command:'
    log "$cmd"
    # Pipe command into MySQL shell and exclude insecure warning messages
    echo "$cmd" | $mysql_shell 2>&1 | grep -v insecure
}

# Remove file if it exists
if [ -e "$OUTFILE" ]
then
    rm "$OUTFILE"
fi

# Export review texts
echo 'Exporting review texts'
rm -f /tmp/result.csv
execute << EOF
use $MYSQL_DB;
select reviewId, asin, reviewText from $MYSQL_TABLE
where reviewText is not null and reviewText <> ''
into outfile '/tmp/result.csv'
fields terminated by ','
optionally enclosed by '"'
escaped by '"'
lines terminated by '\\\n';
EOF
sudo mv /tmp/result.csv "$OUTFILE"

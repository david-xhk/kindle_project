#!/bin/bash

# Log function for debugging purposes
log() {
    # Read input from arguments or stdin
    if [ -z "$1" ]; then read -d '' input; else input="$1"; fi
    # Indent input by 2 spaces
    echo "$input" | sed 's/^/  /'
}

# Command to run MySQL shell (with native root authorization)
mysql_shell='sudo mysql'

# Function to execute MySQL commands
execute() {
    # Read command from arguments or stdin
    if [ -z "$1" ]; then read -d '' cmd; else cmd="$1"; fi
    echo 'Executing MySQL command:'
    log "$cmd"
    # Pipe command into MySQL shell and exclude insecure warning messages
    echo "$cmd" | $mysql_shell 2>&1 | grep -v insecure
}

echo 'Setting up MySQL server'

# Install MySQL
echo 'Installing MySQL'
sudo apt-get update -qq >/dev/null
sudo DEBIAN_FRONTEND=noninteractive apt-get install mysql-server -qq >/dev/null

# Start MySQL service
echo 'Starting MySQL service'
sudo service mysql start

# Wait for MySQL service to be ready to accept connections
echo 'Waiting for MySQL service to be ready...'
until mysqladmin ping
do
    sleep 1
done

# Change MySQL root password
if [ -z "$MYSQL_ROOT_PASSWORD" ]
then
    echo 'Enter MySQL root password:'
    read MYSQL_ROOT_PASSWORD
fi
echo 'Changing MySQL root password'
execute << EOF
alter user 'root'@'localhost' identified with mysql_native_password by '$MYSQL_ROOT_PASSWORD';
flush privileges;
EOF

# New command to run MySQL shell (with root password authorization)
mysql_shell="mysql -u root -h localhost -p$MYSQL_ROOT_PASSWORD"

# Create MySQL database
if [ -z "$MYSQL_DB" ]
then
    echo 'Enter MySQL database name:'
    read MYSQL_DB
fi
echo 'Creating MySQL database'
execute "create database $MYSQL_DB;"

# Create MySQL database users
if [ -z "$MYSQL_USER" ]
then
    echo 'Enter name of MySQL database user:'
    read MYSQL_USER
fi
if [ -z "$MYSQL_PASSWORD" ]
then
    echo 'Enter password for MySQL database user:'
    read MYSQL_PASSWORD
fi
if [ -z "$MYSQL_USER_ADDRESS" ]
then
    echo 'Enter IP address of MySQL database user:'
    read MYSQL_USER_ADDRESS
fi
echo 'Creating MySQL database users'
execute << EOF
create user '$MYSQL_USER'@'$MYSQL_USER_ADDRESS' identified by '$MYSQL_PASSWORD';
grant all on $MYSQL_DB.* to '$MYSQL_USER'@'$MYSQL_USER_ADDRESS';
flush privileges;
EOF
# If developer password and address are provided, create dev user
if [ -n "$MYSQL_DEV_PASSWORD" ] && [ -n "$DEV_ADDRESS" ]
then
    execute <<- EOF
	create user 'dev'@'$DEV_ADDRESS' identified by '$MYSQL_DEV_PASSWORD';
	grant all on \`%\`.* to 'dev'@'$DEV_ADDRESS';
	flush privileges;
	EOF
fi

# Load MySQL database source file
if [ -z "$MYSQL_SOURCE" ]
then
    echo 'Enter name of MySQL database source file:'
    read MYSQL_SOURCE
fi
if [ -z "$MYSQL_TABLE" ]
then
    echo 'Enter name of MySQL database table:'
    read MYSQL_TABLE
fi
echo 'Loading MySQL database source file'
execute << EOF
use $MYSQL_DB;
drop table if exists $MYSQL_TABLE;
create table $MYSQL_TABLE
(
    reviewId int primary key,
    asin varchar(10),
    helpful varchar(30),
    overall int,
    reviewText text,
    reviewTime varchar(11),
    reviewerID varchar(30),
    reviewerName varchar(100),
    summary varchar(500),
    unixReviewTime int(11)
);
load data local infile '$MYSQL_SOURCE' into table $MYSQL_TABLE
fields terminated by ','
optionally enclosed by '"'
escaped by '"'
lines terminated by '\\\r\\\n'
ignore 1 rows
(reviewId, asin, helpful, overall, reviewText, reviewTime, reviewerID, reviewerName, summary, unixReviewTime);
EOF
rm "$MYSQL_SOURCE"

# Create indexes
echo 'Creating indexes'
execute << EOF
use $MYSQL_DB;
create index reviewId on $MYSQL_TABLE (reviewId);
create index asin on $MYSQL_TABLE (asin);
EOF

# Configure MySQL
if [ -z "$MYSQL_BIND_ADDRESS" ]
then
    echo 'Enter MySQL bind address:'
    read MYSQL_BIND_ADDRESS
fi
if [ -z "$MYSQL_MAX_ALLOWED_PACKET" ]
then
    echo 'Enter MySQL max allowed packet:'
    read MYSQL_MAX_ALLOWED_PACKET
fi
echo 'Configuring MySQL'
# Append configuration for bind address
sudo tee -a /etc/mysql/my.cnf << EOF >/dev/null 

[mysqld]
bind-address = $MYSQL_BIND_ADDRESS
max_allowed_packet = $MYSQL_MAX_ALLOWED_PACKET
secure-file-priv = ""
EOF
# Print my.cnf for debugging purposes
echo 'MySQL config file:'
cat /etc/mysql/my.cnf | log

# Restart MySQL service
echo 'Restarting MySQL service'
sudo service mysql restart

# Save MySQL configuration
echo 'Saving MySQL configuration'
cat << EOF >> config
export MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD;
export MYSQL_DB=$MYSQL_DB;
export MYSQL_TABLE=$MYSQL_TABLE;
EOF

#!/bin/bash

echo "Setting up MySQL server..."

# Install MySQL
echo "Installing MySQL..."
sudo apt-get update -qq >/dev/null
sudo DEBIAN_FRONTEND=noninteractive apt-get install mysql-server -qq >/dev/null
echo "Installed MySQL"

# Start MySQL service
echo "Starting MySQL service..."
sudo service mysql start
echo "Started MySQL service"

# Wait for MySQL service to be ready to accept connections
echo "Waiting for MySQL service to be ready..."
until mysqladmin ping
do
    sleep 1
done
echo "MySQL service is ready"

# Change MySQL root password
echo "Changing MySQL root password..."
if [ -z "$MYSQL_ROOT_PASSWORD" ]
then
    echo "Enter MySQL root password:"
    read -s MYSQL_ROOT_PASSWORD
fi
read -d '' cmd << EOF
alter user 'root'@'localhost' identified with mysql_native_password by '$MYSQL_ROOT_PASSWORD';
flush privileges;
EOF
echo "Executing MySQL command:"
echo "$cmd" | sed 's/^/  /'
echo "$cmd" | sudo mysql
echo "Changed MySQL root password"

# Create MySQL database
echo "Creating MySQL database..."
if [ -z "$MYSQL_DB" ]
then
    echo "Enter MySQL database name:"
    read MYSQL_DB
fi
cmd="create database $MYSQL_DB;"
echo "Executing MySQL command:"
echo "$cmd" | sed 's/^/  /'
echo "$cmd" | mysql -u root -h localhost -p$MYSQL_ROOT_PASSWORD 2>&1 | grep -v "insecure"
echo "Created MySQL database"

# Create MySQL database users
echo "Creating MySQL database users..."
if [ -z "$MYSQL_USER" ]
then
    echo "Enter name of MySQL database user:"
    read MYSQL_USER
fi
if [ -z "$MYSQL_PASSWORD" ]
then
    echo "Enter password for MySQL database user:"
    read -s MYSQL_PASSWORD
fi
if [ -z "$MYSQL_USER_ADDRESS" ]
then
    echo "Enter IP address of MySQL database user:"
    read -s MYSQL_USER_ADDRESS
fi
if [ -z "$DEV_PASSWORD" ]
then
    echo "Enter password for development user(s):"
    read -s DEV_PASSWORD
fi
if [ -z "$DEV_ADDRESS" ]
then
    echo "Enter IP address(es) of development user(s):"
    read DEV_ADDRESS
fi
cmd=("create user '$MYSQL_USER'@'$MYSQL_USER_ADDRESS' identified by '$MYSQL_PASSWORD';"
     "grant all on $MYSQL_DB.* to '$MYSQL_USER'@'$MYSQL_USER_ADDRESS';")
for IP in $DEV_ADDRESS
do
    cmd+=("create user 'dev'@'$IP' identified by '$DEV_PASSWORD';"
          "grant all on \`%\`.* to 'dev'@'$IP';")
done
cmd+=("flush privileges;")
IFS=$'\n'; cmd="${cmd[*]}"
echo "Executing MySQL command:"
echo "$cmd" | sed 's/^/  /'
echo "$cmd" | mysql -u root -h localhost -p$MYSQL_ROOT_PASSWORD 2>&1 | grep -v "insecure"
echo "Created MySQL database users"

# Download MySQL database source file
echo "Downloading MySQL database source file..."
if [ -z "$PRODUCTION_HOST" ]
then
    echo "Enter IP address of production server:"
    read PRODUCTION_HOST
fi
if [ -z "$MYSQL_SOURCE" ]
then
    echo "Enter name of MySQL database source file:"
    read MYSQL_SOURCE
fi
wget -q "$PRODUCTION_HOST/$MYSQL_SOURCE"
echo "Downloaded MySQL database source file"

# Load MySQL database source file
echo "Loading MySQL database source file..."
if [ -z "$MYSQL_TABLE" ]
then
    echo "Enter name of MySQL database table:"
    read MYSQL_TABLE
fi
read -d '' cmd << EOF
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
echo "Executing MySQL command:"
echo "$cmd" | sed 's/^/  /'
echo "$cmd" | mysql -u root -h localhost -p$MYSQL_ROOT_PASSWORD 2>&1 | grep -v "insecure"
rm $MYSQL_SOURCE
echo "Loaded MySQL database source file"

# Create indexes
echo "Creating indexes..."
read -d '' cmd << EOF
use $MYSQL_DB;
create index reviewId on $MYSQL_TABLE (reviewId);
create index asin on $MYSQL_TABLE (asin);
EOF
echo "Executing MySQL command:"
echo "$cmd" | sed 's/^/  /'
echo "$cmd" | mysql -u root -h localhost -p$MYSQL_ROOT_PASSWORD 2>&1 | grep -v "insecure"
echo "Created indexes"

# Configure MySQL
echo "Configuring MySQL..."
if [ -z "$MYSQL_BIND_ADDRESS" ]
then
    echo "Enter MySQL bind address:"
    read MYSQL_BIND_ADDRESS
fi
# Append configuration for bind address
sudo tee -a /etc/mysql/my.cnf << EOF >/dev/null 

[mysqld]
bind-address=$MYSQL_BIND_ADDRESS
EOF
# Print my.cnf for verification
echo "MySQL config file:"
cat /etc/mysql/my.cnf | sed 's/^/  /'
echo "Configured MySQL"

# Restart MySQL service
echo "Restarting MySQL service..."
sudo service mysql restart
echo "Restarted MySQL service"

echo "Finished setting up MySQL server"

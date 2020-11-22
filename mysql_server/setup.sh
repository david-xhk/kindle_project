#!/bin/bash

# Install MySQL
echo "Installing MySQL..."
sudo apt-get -q update
sudo DEBIAN_FRONTEND=noninteractive apt-get -q -y install mysql-server # DEBIAN_FRONTEND noninteractive is to skip setting root password
echo "Installed MySQL"

# Start MySQL service
echo "Starting MySQL service..."
sudo service mysql start
echo "Started MySQL service"

# Wait for MySQL service to be ready to accept connections
echo "Waiting for MySQL service to be ready..."
until sudo mysql -e status
do
    echo .
    sleep 1
done
echo "MySQL service is ready"

# Change root password
echo "Changing root password..."
if [ -z "$MYSQL_ROOT_PASS" ]
then
    echo "Enter MySQL root password:"
    read -s MYSQL_ROOT_PASS
fi
read -d '' cmd << EOF
alter user 'root'@'localhost' identified with mysql_native_password by '$MYSQL_ROOT_PASS';
flush privileges;
EOF
echo "$cmd"
sudo mysql -e "$cmd"
echo "Changed root password"

# Create database
echo "Creating database..."
if [ -z "$MYSQL_DB" ]
then
    echo "Enter MySQL database name:"
    read MYSQL_DB
fi
cmd="create database $MYSQL_DB;"
echo "$cmd"
mysql -u root -h localhost -p$MYSQL_ROOT_PASS -e "$cmd"
echo "Created database"

# Create users
echo "Creating users..."
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
if [ -z "$MYSQL_USER_ADDR" ]
then
    echo "Enter IP address of MySQL database user:"
    read -s MYSQL_USER_ADDR
fi
if [ -z "$DEV_PASSWORD" ]
then
    echo "Enter password for development user(s):"
    read -s DEV_PASSWORD
fi
if [ -z "$DEV_IP" ]
then
    echo "Enter IP address(es) of development user(s):"
    read DEV_IP
fi
cmd=("create user '$MYSQL_USER'@'$MYSQL_USER_ADDR' identified by '$MYSQL_PASSWORD';"
     "grant all on $MYSQL_DB.* to '$MYSQL_USER'@'$MYSQL_USER_ADDR';")
for IP in $DEV_IP; do
    cmd+=("create user 'dev'@'$IP' identified by '$DEV_PASSWORD';"
          "grant all on \`%\`.* to 'dev'@'$IP';")
done
cmd+=("flush privileges;")
IFS=$'\n'; cmd="${cmd[*]}"
echo "$cmd"
mysql -u root -h localhost -p$MYSQL_ROOT_PASS -e "$cmd"
echo "Created users"

# Download kindle_reviews.csv
echo "Downloading kindle_reviews.csv..."
if [ -z "$PROD_IP" ]
then
    echo "Enter IP address of production server:"
    read PROD_IP
fi
wget -q "$PROD_IP/kindle_reviews.csv"
echo "Downloaded kindle_reviews.csv"

# Load kindle_reviews.csv
echo "Loading kindle_reviews.csv..."
read -d '' cmd << EOF
use $MYSQL_DB;

drop table if exists kindle_reviews;

create table kindle_reviews
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

load data local infile 'kindle_reviews.csv' into table kindle_reviews
fields terminated by ','
optionally enclosed by '"'
escaped by '"'
lines terminated by '\\\r\\\n'
ignore 1 rows
(reviewId, asin, helpful, overall, reviewText, reviewTime, reviewerID, reviewerName, summary, unixReviewTime);
EOF
echo "$cmd"
mysql -h localhost -u root -p$MYSQL_ROOT_PASS -e "$cmd"
rm kindle_reviews.csv
echo "Loaded kindle_reviews.csv"

# Create indexes
echo "Creating indexes..."
read -d '' cmd << EOF
use $MYSQL_DB;
create index reviewId on kindle_reviews (reviewId);
create index asin on kindle_reviews (asin);
EOF
mysql -h localhost -u root -p$MYSQL_ROOT_PASS -e "$cmd"
echo "Created indexes"

# Configure MySQL
echo "Configuring MySQL..."
if [ -z "$MYSQL_BIND_ADDR" ]
then
    echo "Enter MySQL bind address:"
    read MYSQL_BIND_ADDR
fi
# Append configuration for bind address
sudo tee -a /etc/mysql/my.cnf << EOF

[mysqld]
bind-address=$MYSQL_BIND_ADDR
EOF
# Print my.cnf for verification
cat /etc/mysql/my.cnf
echo "Configured MySQL"

# Restart MySQL service
echo "Restarting MySQL service..."
sudo service mysql restart
echo "Restarted MySQL service"

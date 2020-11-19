#!/bin/bash

# Update system and install MySQL server
sudo apt-get update
sudo apt-get install mysql-server --yes

# Configure MySQL bind address
echo "Enter MySQL bind address:"
read BIND_IP
sudo tee /etc/mysql/my.cnf << MYSQL_CONF
[mysqld]
bind-address=$BIND_IP
MYSQL_CONF
sudo service mysql restart
echo "MySQL configured"

# Create database
echo "Enter root password:"
read -s ROOT
echo "Enter new database name:"
read DB
echo "Creating database..."
mysql -uroot -p$ROOT -e "create database $DB;"
echo "Database created"

# Create new user
echo "Enter name of new database user:"
read USER
echo "Enter password for new database user:"
read -s PASS
echo "Enter IP address of new database user:"
read USER_IP
echo "Creating user..."
mysql -uroot -p$ROOT << CREATE_USER
create user '$USER'@'$USER_IP' identified by '$PASS';
grant all privileges on $DB.* to '$USER'@'$USER_IP' with grant option;
flush privileges;
CREATE_USER
echo "User created"

# Download and load kindle_reviews.csv
echo "Enter IP address of production server:"
read PROD_IP
echo "Downloading kindle_reviews.csv..."
wget "$PROD_IP/kindle_reviews.csv"
echo "kindle_reviews.csv downloaded"
echo "Loading kindle_reviews.csv..."
mysql -uroot -p$ROOT << LOAD_DATA
use $DB;
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
lines terminated by '\r\n'
ignore 1 rows
(reviewId, asin, helpful, overall, reviewText, reviewTime, reviewerID, reviewerName, summary, unixReviewTime);
LOAD_DATA
echo "kindle_reviews.csv loaded"

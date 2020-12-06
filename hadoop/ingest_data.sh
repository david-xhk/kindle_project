#!/bin/bash

# Load Hadoop configuration
echo 'Loading Hadoop configuration'
source config

# Connect to MySQL server
if [ -z "$MYSQL_PRIVATE_IPV4" ]
then
    echo 'Enter MySQL private IPv4 address:'
    read MYSQL_PRIVATE_IPV4
fi
echo 'Connecting to MySQL server'
ssh $SSH_OPTIONS "ubuntu@$MYSQL_PRIVATE_IPV4" 'sudo ./export_review_texts.sh ~/review_texts.csv'

# Copy review texts
echo 'Copying review texts'
scp $SSH_OPTIONS "ubuntu@$MYSQL_PRIVATE_IPV4:~/review_texts.csv" .

# Connect to MongoDB server
if [ -z "$MONGO_PRIVATE_IPV4" ]
then
    echo 'Enter MongoDB private IPv4 address:'
    read MONGO_PRIVATE_IPV4
fi
echo 'Connecting to MongoDB server'
ssh $SSH_OPTIONS "ubuntu@$MONGO_PRIVATE_IPV4" './export_prices.sh ~/prices.csv'

# Copy prices
echo 'Copying prices'
scp $SSH_OPTIONS "ubuntu@$MONGO_PRIVATE_IPV4:~/prices.csv" .

# Ingest files
echo 'Ingesting files'
sudo mv *.csv /home/hadoop
sudo chown hadoop:hadoop /home/hadoop/*.csv
sudo -i -u hadoop bash -c 'start-dfs.sh; hdfs dfs -test -d /input || hdfs dfs -mkdir /input; hdfs dfs -rm -f /input/*; hdfs dfs -moveFromLocal *.csv /input; stop-dfs.sh'

#!/bin/bash

# Start HDFS
echo 'Starting HDFS'
start-dfs.sh

# Wait for HDFS to start
echo 'Waiting for HDFS to start...'
until sudo -i -u hadoop bash -c 'hdfs dfsadmin -safemode get' | grep -q -v ON
do
    sleep 3
done

# Start YARN
echo 'Starting YARN'
start-yarn.sh

# Start Spark
echo 'Starting Spark'
start-all.sh

#!/bin/bash

# Stop Spark
echo 'Stopping Spark'
stop-all.sh

# Stop YARN
echo 'Stopping YARN'
stop-yarn.sh

# Stop HDFS
echo 'Stopping HDFS'
stop-dfs.sh

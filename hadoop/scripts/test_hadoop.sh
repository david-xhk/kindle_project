#!/bin/bash

# Download lab files
echo 'Downloading lab files'
git clone https://github.com/istd50043-2020-fall/sutd50043_student

# Prepare to put data into HDFS
echo 'Preparing to put data into HDFS'
hdfs dfs -mkdir /input
hdfs dfs -rm -f -r /output

# Put data into HDFS
echo 'Putting data into HDFS'
hdfs dfs -put sutd50043_student/lab10/data/TheCompleteSherlockHolmes.txt /input

# Submit wordcount job
echo 'Submitting wordcount job'
hadoop jar /opt/hadoop-3.3.0/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.0.jar wordcount /input /output

# Get output
echo 'Getting output'
hdfs dfs -cat /output/* 2>/dev/null | head -20

# Cleanup
echo 'Cleaning up'
hdfs dfs -rm -f -r /input /output

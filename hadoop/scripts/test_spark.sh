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

# Update wordcount.py
echo 'Updating wordcount.py'
PRIVATE_IP=$(hostname -I)
sed -i "s/localhost/${PRIVATE_IP%% }/g" sutd50043_student/lab13/wordcount.py

# Submit wordcount job
echo 'Submitting wordcount job'
spark-submit --master yarn sutd50043_student/lab13/wordcount.py

# Get output
echo 'Getting output'
hdfs dfs -cat /output/* 2>/dev/null | head -20

# Cleanup
echo 'Cleaning up'
hdfs dfs -rm -f -r /input /output

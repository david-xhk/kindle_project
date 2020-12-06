#!/bin/bash

# Load configuration
echo 'Loading configuration'
source config

# Load defaults
echo 'Loading defaults'
source defaults

# Connect to Hadoop cluster and run scripts to ingest data and run analytics
ssh $SSH_OPTIONS -i "$AWS_KEY_PAIR_NAME.pem" "ubuntu@$HADOOP_MASTER_PUBLIC_IPV4" "./ingest_data.sh; ./run_analytics.sh"

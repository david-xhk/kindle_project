#!/bin/bash

# Load configuration
if [ ! -e config ]
then
    echo 'Nothing to teardown: Could not locate configuration file'
    exit 1
fi
echo 'Loading configuration'
source config

# Load defaults
echo 'Loading defaults'
source defaults

# Set AWS profile
echo 'Setting AWS profile'
export AWS_PROFILE=$AWS_PROFILE_NAME

# Terminate EC2 instances
echo 'Terminating EC2 instances'
[ -n "$HADOOP_MASTER_INSTANCE_ID" ] && aws ec2 terminate-instances --instance-ids "$HADOOP_MASTER_INSTANCE_ID" --query 'TerminatingInstances[*].CurrentState.Name' --output text 2>/dev/null
for INSTANCE_ID in $HADOOP_WORKERS_INSTANCE_ID
do
    aws ec2 terminate-instances --instance-ids "$INSTANCE_ID" --query 'TerminatingInstances[*].CurrentState.Name' --output text 2>/dev/null
done
[ -n "$FLASK_INSTANCE_ID" ] && aws ec2 terminate-instances --instance-ids "$FLASK_INSTANCE_ID" --query 'TerminatingInstances[*].CurrentState.Name' --output text 2>/dev/null
[ -n "$MONGO_INSTANCE_ID" ] && aws ec2 terminate-instances --instance-ids "$MONGO_INSTANCE_ID" --query 'TerminatingInstances[*].CurrentState.Name' --output text 2>/dev/null
[ -n "$MYSQL_INSTANCE_ID" ] && aws ec2 terminate-instances --instance-ids "$MYSQL_INSTANCE_ID" --query 'TerminatingInstances[*].CurrentState.Name' --output text 2>/dev/null

# Wait for EC2 instances to terminate
echo 'Waiting for EC2 instances to terminate...'
[ -n "$HADOOP_MASTER_INSTANCE_ID" ] && aws ec2 wait instance-terminated --instance-ids "$HADOOP_MASTER_INSTANCE_ID" 2>/dev/null
for INSTANCE_ID in $HADOOP_WORKERS_INSTANCE_ID
do
    aws ec2 wait instance-terminated --instance-ids "$INSTANCE_ID" 2>/dev/null
done
[ -n "$FLASK_INSTANCE_ID" ] && aws ec2 wait instance-terminated --instance-ids "$FLASK_INSTANCE_ID" 2>/dev/null
[ -n "$MONGO_INSTANCE_ID" ] && aws ec2 wait instance-terminated --instance-ids "$MONGO_INSTANCE_ID" 2>/dev/null
[ -n "$MYSQL_INSTANCE_ID" ] && aws ec2 wait instance-terminated --instance-ids "$MYSQL_INSTANCE_ID" 2>/dev/null

# Delete security groups
echo 'Deleting security groups'
[ -n "$HADOOP_GROUP_ID" ] && aws ec2 delete-security-group --group-id "$HADOOP_GROUP_ID" 2>/dev/null
[ -n "$FLASK_GROUP_ID" ] && aws ec2 delete-security-group --group-id "$FLASK_GROUP_ID" 2>/dev/null
[ -n "$MONGO_GROUP_ID" ] && aws ec2 delete-security-group --group-id "$MONGO_GROUP_ID" 2>/dev/null
[ -n "$MYSQL_GROUP_ID" ] && aws ec2 delete-security-group --group-id "$MYSQL_GROUP_ID" 2>/dev/null

# Delete AWS key pair
echo 'Deleting AWS key pair'
if [ -n "$AWS_KEY_PAIR_NAME" ]
then
    aws ec2 delete-key-pair --key-name "$AWS_KEY_PAIR_NAME" 2>/dev/null
    chmod 644 "$AWS_KEY_PAIR_NAME.pem" 2>/dev/null
    rm "$AWS_KEY_PAIR_NAME.pem" 2>/dev/null
fi

# Remove AWS profile
echo 'Removing AWS profile'
sed -i "/[$AWS_PROFILE]/,/^\$/d" ~/.aws/credentials 2>/dev/null
sed -i "/[profile $AWS_PROFILE]/,/^\$/d" ~/.aws/config 2>/dev/null

# Remove config file
echo 'Removing config file'
rm config 2>/dev/null

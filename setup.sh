#!/bin/bash

# Custom function for screen
screen-log() {
    script="$(mktemp)"
    cat > $script
    chmod u+x $script
    name="$1"
    logfile="logs/$name.log"
    [ ! -d logs ] && mkdir logs
    [ -e "$logfile" ] && rm "$logfile"
    screen -dmS "$name" $script
    screen -S "$name" -X logfile "$logfile"
    screen -S "$name" -X logfile flush 1
    screen -S "$name" -X log
    rm $script
}

# Load defaults
echo 'Loading defaults'
source defaults

# Load credentials
echo 'Loading credentials'
source credentials

# Install AWS CLI
if [ $(dpkg-query -l | grep awscli | wc -l) -eq 0 ]
then
    echo 'Installing AWS CLI'
    sudo apt install awscli --yes
fi

# Set AWS profile
if [ -z "$AWS_PROFILE_NAME" ]
then
    echo 'Enter AWS profile:'
    read AWS_PROFILE_NAME
fi
aws configure list --profile "$AWS_PROFILE_NAME" &>/dev/null
if [ $? -ne 0 ]
then
    echo 'Configuring AWS profile'
    if [ -z "$AWS_ACCESS_KEY_ID" ]
    then
        echo 'Enter AWS access key id:'
        read AWS_ACCESS_KEY_ID
    fi
    if [ -n "$AWS_ACCESS_KEY_ID" ]
    then
        aws configure set "profile.$AWS_PROFILE_NAME.aws_access_key_id" "$AWS_ACCESS_KEY_ID"
    fi
    if [ -z "$AWS_SECRET_ACCESS_KEY" ]
    then
        echo 'Enter AWS secret access key:'
        read AWS_SECRET_ACCESS_KEY
    fi
    if [ -n "$AWS_SECRET_ACCESS_KEY" ]
    then
        aws configure set "profile.$AWS_PROFILE_NAME.aws_secret_access_key" "$AWS_SECRET_ACCESS_KEY"
    fi
    if [ -z "$AWS_SESSION_TOKEN" ]
    then
        echo 'Enter AWS session token (if any):'
        read AWS_SESSION_TOKEN
    fi
    if [ -n "$AWS_SESSION_TOKEN" ]
    then
        aws configure set "profile.$AWS_PROFILE_NAME.aws_session_token" "$AWS_SESSION_TOKEN"
    fi
    if [ -z "$AWS_REGION" ]
    then
        echo 'Enter region:'
        read AWS_REGION
    fi
    if [ -n "$AWS_REGION" ]
    then
        aws configure set "profile.$AWS_PROFILE_NAME.region" "$AWS_REGION"
    fi
fi
echo 'Setting AWS profile'
export AWS_PROFILE="$AWS_PROFILE_NAME"

# Create AWS key pair
if [ -z "$AWS_KEY_PAIR_NAME" ]
then
    echo 'Enter AWS key pair name:'
    read AWS_KEY_PAIR_NAME
fi
aws ec2 describe-key-pairs --key-names "$AWS_KEY_PAIR_NAME" &>/dev/null
if [ $? -ne 0 ]
then
    echo 'Creating AWS key pair'
    aws ec2 create-key-pair --key-name "$AWS_KEY_PAIR_NAME" --query 'KeyMaterial' --output text > "$AWS_KEY_PAIR_NAME.pem"
    chmod 400 "$AWS_KEY_PAIR_NAME.pem"

    # Wait for key pair to exist
    aws ec2 wait key-pair-exists --key-names "$AWS_KEY_PAIR_NAME"
fi

# Create security groups
MYSQL_GROUP_ID=$(aws ec2 describe-security-groups --filters Name=description,Values='Security group for MySQL server' --query 'SecurityGroups[*].[GroupId]' --output text)
if [ -n "$MYSQL_GROUP_ID" ]
then
    echo 'Deleting previous security group for MySQL server'
    echo 'Waiting to delete previous security group for MySQL server...'
    until aws ec2 delete-security-group --group-id "$MYSQL_GROUP_ID" &>/dev/null
    do   
       sleep 3
    done
fi
echo 'Creating security group for MySQL server'
MYSQL_GROUP_ID=$(aws ec2 create-security-group --group-name 'MySQLServer' --description 'Security group for MySQL server' --output text) 
echo "export MYSQL_GROUP_ID=$MYSQL_GROUP_ID;" >> config

MONGO_GROUP_ID=$(aws ec2 describe-security-groups --filters Name=description,Values='Security group for MongoDB server' --query 'SecurityGroups[*].[GroupId]' --output text)
if [ -n "$MONGO_GROUP_ID" ]
then
    echo 'Deleting previous security group for MongoDB server'
    echo 'Waiting to delete previous security group for MongoDB server...'
    until aws ec2 delete-security-group --group-id "$MONGO_GROUP_ID" &>/dev/null
    do
       sleep 3
    done
fi
echo 'Creating security group for MongoDB server'
MONGO_GROUP_ID=$(aws ec2 create-security-group --group-name 'MongoDBServer' --description 'Security group for MongoDB server' --output text)
echo "export MONGO_GROUP_ID=$MONGO_GROUP_ID;" >> config

FLASK_GROUP_ID=$(aws ec2 describe-security-groups --filters Name=description,Values='Security group for Flask server' --query 'SecurityGroups[*].[GroupId]' --output text)
if [ -n "$FLASK_GROUP_ID" ]
then
    echo 'Deleting previous security group for Flask server'
    echo 'Waiting to delete previous security group for Flask server...'
    until aws ec2 delete-security-group --group-id "$FLASK_GROUP_ID" &>/dev/null
    do
       sleep 3
    done
fi
echo 'Creating security group for Flask server'
FLASK_GROUP_ID=$(aws ec2 create-security-group --group-name 'FlaskServer' --description 'Security group for Flask server' --output text)
echo "export FLASK_GROUP_ID=$FLASK_GROUP_ID;" >> config

HADOOP_GROUP_ID=$(aws ec2 describe-security-groups --filters Name=description,Values='Security group for Hadoop cluster' --query 'SecurityGroups[*].[GroupId]' --output text)
if [ -n "$HADOOP_GROUP_ID" ]
then
    echo 'Deleting previous security group for Hadoop cluster'
    echo 'Waiting to delete previous security group for Hadoop cluster...'
    until aws ec2 delete-security-group --group-id "$HADOOP_GROUP_ID" &>/dev/null
    do
       sleep 3
    done
fi
echo 'Creating security group for Hadoop cluster'
HADOOP_GROUP_ID=$(aws ec2 create-security-group --group-name 'HadoopCluster' --description 'Security group for Hadoop cluster' --output text)
echo "export HADOOP_GROUP_ID=$HADOOP_GROUP_ID;" >> config

# Wait for security groups to be created
echo 'Waiting for security groups to be created...'
aws ec2 wait security-group-exists --group-ids "$MYSQL_GROUP_ID"
aws ec2 wait security-group-exists --group-ids "$MONGO_GROUP_ID"
aws ec2 wait security-group-exists --group-ids "$FLASK_GROUP_ID"
aws ec2 wait security-group-exists --group-ids "$HADOOP_GROUP_ID"

# Launch EC2 instances
if [ -z "$MYSQL_IMAGE_ID" ]
then
    echo 'Enter MySQL EC2 instance machine image id:'
    read MYSQL_IMAGE_ID
fi
if [ -z "$MYSQL_INSTANCE_TYPE" ]
then
    echo 'Enter MySQL EC2 instance type:'
    read MYSQL_INSTANCE_TYPE
fi
echo 'Launching EC2 instance for MySQL server'
MYSQL_INSTANCE_ID="$(aws ec2 run-instances --image-id $MYSQL_IMAGE_ID --count 1 --instance-type $MYSQL_INSTANCE_TYPE --key-name $AWS_KEY_PAIR_NAME --security-group-ids $MYSQL_GROUP_ID --query 'Instances[*].InstanceId' --output text)"
echo "export MYSQL_INSTANCE_ID=$MYSQL_INSTANCE_ID;" >> config

if [ -z "$MONGO_IMAGE_ID" ]
then
    echo 'Enter MongoDB EC2 instance machine image id:'
    read MONGO_IMAGE_ID
fi
if [ -z "$MONGO_INSTANCE_TYPE" ]
then
    echo 'Enter MongoDB EC2 instance type:'
    read MONGO_INSTANCE_TYPE
fi
echo 'Launching EC2 instance for MongoDB server'
MONGO_INSTANCE_ID="$(aws ec2 run-instances --image-id $MONGO_IMAGE_ID --count 1 --instance-type $MONGO_INSTANCE_TYPE --key-name $AWS_KEY_PAIR_NAME --security-group-ids $MONGO_GROUP_ID --query 'Instances[*].InstanceId' --output text)"
echo "export MONGO_INSTANCE_ID=$MONGO_INSTANCE_ID;" >> config

if [ -z "$FLASK_IMAGE_ID" ]
then
    echo 'Enter Flask server EC2 instance machine image id:'
    read FLASK_IMAGE_ID
fi
if [ -z "$FLASK_INSTANCE_TYPE" ]
then
    echo 'Enter Flask server EC2 instance type:'
    read FLASK_INSTANCE_TYPE
fi
echo 'Launching EC2 instance for Flask server'
FLASK_INSTANCE_ID="$(aws ec2 run-instances --image-id $FLASK_IMAGE_ID --count 1 --instance-type $FLASK_INSTANCE_TYPE --key-name $AWS_KEY_PAIR_NAME --security-group-ids $FLASK_GROUP_ID --query 'Instances[*].InstanceId' --output text)"
echo "export FLASK_INSTANCE_ID=$FLASK_INSTANCE_ID;" >> config

if [ -z "$HADOOP_MASTER" ]
then
    echo 'Enter name of Hadoop master node:'
    read HADOOP_MASTER
fi
if [ -z "$HADOOP_MASTER_IMAGE_ID" ]
then
    echo 'Enter Hadoop master machine image id:'
    read HADOOP_MASTER_IMAGE_ID
fi
if [ -z "$HADOOP_MASTER_INSTANCE_TYPE" ]
then
    echo 'Enter Hadoop master instance type:'
    read HADOOP_MASTER_INSTANCE_TYPE
fi
echo 'Launching EC2 instance for Hadoop master'
HADOOP_MASTER_INSTANCE_ID="$(aws ec2 run-instances --image-id $HADOOP_MASTER_IMAGE_ID --count 1 --instance-type $HADOOP_MASTER_INSTANCE_TYPE --key-name $AWS_KEY_PAIR_NAME --security-group-ids $HADOOP_GROUP_ID --query 'Instances[*].InstanceId' --output text)"
cat << EOF >> config
export HADOOP_MASTER=$HADOOP_MASTER;
export HADOOP_MASTER_INSTANCE_ID=$HADOOP_MASTER_INSTANCE_ID;
EOF

if [ -z "$HADOOP_WORKER_PREFIX" ]
then
    echo 'Enter prefix of Hadoop worker node:'
    read HADOOP_WORKER_PREFIX
fi
if [ -z "$HADOOP_NUM_WORKERS" ]
then
    echo 'Enter number of Hadoop worker nodes:'
    read HADOOP_NUM_WORKERS
fi
if [ -z "$HADOOP_WORKER_IMAGE_ID" ]
then
    echo 'Enter Hadoop worker machine image id:'
    read HADOOP_WORKER_IMAGE_ID
fi
if [ -z "$HADOOP_WORKER_INSTANCE_TYPE" ]
then
    echo 'Enter Hadoop worker instance type:'
    read HADOOP_WORKER_INSTANCE_TYPE
fi
echo 'Launching EC2 instances for Hadoop workers'
HADOOP_WORKERS="$HADOOP_WORKER_PREFIX-0"
HADOOP_WORKERS_INSTANCE_ID="$(aws ec2 run-instances --image-id $HADOOP_WORKER_IMAGE_ID --count 1 --instance-type $HADOOP_WORKER_INSTANCE_TYPE --key-name $AWS_KEY_PAIR_NAME --security-group-ids $HADOOP_GROUP_ID --query 'Instances[*].InstanceId' --output text)"
i=1
while [[ $i -lt $HADOOP_NUM_WORKERS ]]
do
    HADOOP_WORKERS+=" $HADOOP_WORKER_PREFIX-$i"
    HADOOP_WORKERS_INSTANCE_ID+=" $(aws ec2 run-instances --image-id $HADOOP_WORKER_IMAGE_ID --count 1 --instance-type $HADOOP_WORKER_INSTANCE_TYPE --key-name $AWS_KEY_PAIR_NAME --security-group-ids $HADOOP_GROUP_ID --query 'Instances[*].InstanceId' --output text)"
    i=$(($i+1))
done
cat << EOF >> config
export HADOOP_WORKERS='$HADOOP_WORKERS';
export HADOOP_WORKERS_INSTANCE_ID='$HADOOP_WORKERS_INSTANCE_ID';
EOF

# Wait for EC2 instances to run
echo 'Waiting for EC2 instances to run...'
aws ec2 wait instance-running --instance-ids "$MYSQL_INSTANCE_ID"
aws ec2 wait instance-running --instance-ids "$MONGO_INSTANCE_ID"
aws ec2 wait instance-running --instance-ids "$FLASK_INSTANCE_ID"
aws ec2 wait instance-running --instance-ids "$HADOOP_MASTER_INSTANCE_ID"
for INSTANCE_ID in $HADOOP_WORKERS_INSTANCE_ID
do
    aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"
done

# Get information about EC2 instances
echo 'Getting information about EC2 instances'
MYSQL_PRIVATE_IPV4="$(aws ec2 describe-instances --instance-ids $MYSQL_INSTANCE_ID --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)"
MYSQL_PUBLIC_IPV4="$(aws ec2 describe-instances --instance-ids $MYSQL_INSTANCE_ID --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)"
MONGO_PRIVATE_IPV4="$(aws ec2 describe-instances --instance-ids $MONGO_INSTANCE_ID --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)"
MONGO_PUBLIC_IPV4="$(aws ec2 describe-instances --instance-ids $MONGO_INSTANCE_ID --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)"
FLASK_PRIVATE_IPV4="$(aws ec2 describe-instances --instance-ids $FLASK_INSTANCE_ID --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)"
FLASK_PUBLIC_IPV4="$(aws ec2 describe-instances --instance-ids $FLASK_INSTANCE_ID --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)"
FLASK_PUBLIC_DNS="$(aws ec2 describe-instances --instance-ids $FLASK_INSTANCE_ID --query 'Reservations[*].Instances[*].PublicDnsName' --output text)"
HADOOP_MASTER_PUBLIC_IPV4="$(aws ec2 describe-instances --instance-ids $HADOOP_MASTER_INSTANCE_ID --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)"
HADOOP_MASTER_PRIVATE_IPV4="$(aws ec2 describe-instances --instance-ids $HADOOP_MASTER_INSTANCE_ID --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)"
HADOOP_WORKERS_PUBLIC_IPV4=""
HADOOP_WORKERS_PRIVATE_IPV4=""
for INSTANCE_ID in $HADOOP_WORKERS_INSTANCE_ID
do
    HADOOP_WORKERS_PUBLIC_IPV4+=" $(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)"
    HADOOP_WORKERS_PRIVATE_IPV4+=" $(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)"
done
HADOOP_WORKERS_PUBLIC_IPV4="${HADOOP_WORKERS_PUBLIC_IPV4## }"
HADOOP_WORKERS_PRIVATE_IPV4="${HADOOP_WORKERS_PRIVATE_IPV4## }"
cat << EOF >> config
export MYSQL_PRIVATE_IPV4=$MYSQL_PRIVATE_IPV4;
export MYSQL_PUBLIC_IPV4=$MYSQL_PUBLIC_IPV4;
export MYSQL_USER_ADDRESS=$FLASK_PRIVATE_IPV4;
export MONGO_PRIVATE_IPV4=$MONGO_PRIVATE_IPV4;
export MONGO_PUBLIC_IPV4=$MONGO_PUBLIC_IPV4;
export FLASK_PRIVATE_IPV4=$FLASK_PRIVATE_IPV4;
export FLASK_PUBLIC_IPV4=$FLASK_PUBLIC_IPV4;
export FLASK_PUBLIC_DNS=$FLASK_PUBLIC_DNS;
export HADOOP_MASTER_PUBLIC_IPV4=$HADOOP_MASTER_PUBLIC_IPV4;
export HADOOP_MASTER_PRIVATE_IPV4=$HADOOP_MASTER_PRIVATE_IPV4;
export HADOOP_WORKERS_PUBLIC_IPV4='$HADOOP_WORKERS_PUBLIC_IPV4';
export HADOOP_WORKERS_PRIVATE_IPV4='$HADOOP_WORKERS_PRIVATE_IPV4';
EOF

# Get developer public IPv4 address
echo 'Getting developer IP address'
DEV_ADDRESS="$(curl -s https://checkip.amazonaws.com/)"

# Configure security groups
echo 'Configuring security group for MySQL server'
aws ec2 authorize-security-group-ingress --group-id "$MYSQL_GROUP_ID" --protocol tcp --port 22 --cidr "$DEV_ADDRESS/32"
aws ec2 authorize-security-group-ingress --group-id "$MYSQL_GROUP_ID" --protocol tcp --port 22 --source-group "$HADOOP_GROUP_ID"
aws ec2 authorize-security-group-ingress --group-id "$MYSQL_GROUP_ID" --protocol tcp --port "$MYSQL_PORT" --cidr "$DEV_ADDRESS/32"
aws ec2 authorize-security-group-ingress --group-id "$MYSQL_GROUP_ID" --protocol tcp --port "$MYSQL_PORT" --cidr "$FLASK_PRIVATE_IPV4/32"

echo 'Configuring security group for MongoDB server'
aws ec2 authorize-security-group-ingress --group-id "$MONGO_GROUP_ID" --protocol tcp --port 22 --cidr "$DEV_ADDRESS/32"
aws ec2 authorize-security-group-ingress --group-id "$MONGO_GROUP_ID" --protocol tcp --port 22 --source-group "$HADOOP_GROUP_ID"
aws ec2 authorize-security-group-ingress --group-id "$MONGO_GROUP_ID" --protocol tcp --port "$MONGO_PORT" --cidr "$DEV_ADDRESS/32"
aws ec2 authorize-security-group-ingress --group-id "$MONGO_GROUP_ID" --protocol tcp --port "$MONGO_PORT" --cidr "$FLASK_PRIVATE_IPV4/32"

echo 'Configuring security group for Flask server'
aws ec2 authorize-security-group-ingress --group-id "$FLASK_GROUP_ID" --protocol tcp --port 22 --cidr "$DEV_ADDRESS/32"
aws ec2 authorize-security-group-ingress --group-id "$FLASK_GROUP_ID" --protocol tcp --port 22 --source-group "$HADOOP_GROUP_ID"
aws ec2 authorize-security-group-ingress --group-id "$FLASK_GROUP_ID" --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id "$FLASK_GROUP_ID" --protocol tcp --port "$MYSQL_PORT" --cidr "$MYSQL_PRIVATE_IPV4/32"
aws ec2 authorize-security-group-ingress --group-id "$FLASK_GROUP_ID" --protocol tcp --port "$MONGO_PORT" --cidr "$MONGO_PRIVATE_IPV4/32"

echo 'Configuring security group for Hadoop cluster'
aws ec2 authorize-security-group-ingress --group-id "$HADOOP_GROUP_ID" --protocol -1 --port -1 --source-group "$HADOOP_GROUP_ID"
aws ec2 authorize-security-group-ingress --group-id "$HADOOP_GROUP_ID" --protocol tcp --port 22 --cidr "$DEV_ADDRESS/32"
aws ec2 authorize-security-group-ingress --group-id "$HADOOP_GROUP_ID" --protocol tcp --port 22 --cidr "$MYSQL_PRIVATE_IPV4/32"
aws ec2 authorize-security-group-ingress --group-id "$HADOOP_GROUP_ID" --protocol tcp --port 22 --cidr "$MONGO_PRIVATE_IPV4/32"
aws ec2 authorize-security-group-ingress --group-id "$HADOOP_GROUP_ID" --protocol tcp --port 22 --cidr "$FLASK_PRIVATE_IPV4/32"

# Create SSH key for Hadoop cluster
if [ ! -e hadoop/id_rsa ] || [ ! -e hadoop/id_rsa.pub ]
then
    rm -f hadoop/id_rsa*
    echo 'Creating SSH key for Hadoop cluster'
    ssh-keygen -q -f hadoop/id_rsa -t rsa -N '' -C 'Hadoop cluster public key'
fi

# Download MySQL source file
if [ ! -e "mysql_server/$MYSQL_SOURCE" ]
then
    if [ -z "$MYSQL_SOURCE_URL" ]
    then
        echo 'Enter url for MySQL source file:'
        read MYSQL_SOURCE_URL
    fi
    echo 'Downloading MySQL source file'
    wget -q "$MYSQL_SOURCE_URL" -P mysql_server -O "$MYSQL_SOURCE"
fi

# Start screen for MySQL server
echo 'Starting screen for MySQL server'
screen-log mysql_server << EOF
echo 'Copying files to MySQL server'
scp $SSH_OPTIONS -i "$AWS_KEY_PAIR_NAME.pem" -r mysql_server/* "ubuntu@$MYSQL_PUBLIC_IPV4:~"
ssh $SSH_OPTIONS -i "$AWS_KEY_PAIR_NAME.pem" "ubuntu@$MYSQL_PUBLIC_IPV4" "export DEV_ADDRESS=$DEV_ADDRESS; echo '$(cat hadoop/id_rsa.pub)' | sudo tee -a ~/.ssh/authorized_keys >/dev/null; $(grep -E '(HADOOP|FLASK|MYSQL)' < defaults) $(grep -E '(HADOOP|FLASK|MYSQL)' < credentials) $(grep -E '(HADOOP|FLASK|MYSQL)' < config) sudo -E ./setup.sh"
EOF

# Download MongoDB source file
if [ ! -e "mongodb_server/$MONGO_SOURCE" ]
then
    if [ -z "$MONGO_SOURCE_URL" ]
    then
        echo 'Enter url for MongoDB source file:'
        read MONGO_SOURCE_URL
    fi
    echo 'Downloading MongoDB source file'
    wget -q "$MONGO_SOURCE_URL" -P mongodb_server -O "$MONGO_SOURCE"
fi

# Start screen for MongoDB server
echo 'Starting screen for MongoDB server'
screen-log mongodb_server << EOF
echo 'Copying files to MongoDB server'
scp $SSH_OPTIONS -i "$AWS_KEY_PAIR_NAME.pem" -r mongodb_server/* "ubuntu@$MONGO_PUBLIC_IPV4:~"
ssh $SSH_OPTIONS -i "$AWS_KEY_PAIR_NAME.pem" "ubuntu@$MONGO_PUBLIC_IPV4" "echo '$(cat hadoop/id_rsa.pub)' | sudo tee -a ~/.ssh/authorized_keys >/dev/null; $(grep MONGO < defaults) $(grep MONGO < credentials) $(grep MONGO < config) sudo -E ./setup.sh"
EOF

# Download Hadoop
if [ ! -e hadoop/hadoop-3.3.0.tar.gz ]
then
    echo 'Downloading Hadoop'
    wget -q https://apachemirror.sg.wuchna.com/hadoop/common/hadoop-3.3.0/hadoop-3.3.0.tar.gz -P hadoop
fi

# Download Spark
if [ ! -e hadoop/spark-3.0.1-bin-hadoop3.2.tgz ]
then
    echo 'Downloading Spark'
    wget -q https://apachemirror.sg.wuchna.com/spark/spark-3.0.1/spark-3.0.1-bin-hadoop3.2.tgz -P hadoop
fi

i=0
while [[ $i -lt $HADOOP_NUM_WORKERS ]]
do
    WORKER_NAME="$(cut -d' ' -f$(($i+1)) <<< $HADOOP_WORKERS)"
    WORKER_IP="$(cut -d' ' -f$(($i+1)) <<< $HADOOP_WORKERS_PUBLIC_IPV4)"

    # Start screen for Hadoop worker
    echo 'Starting screen for Hadoop worker'
    screen-log "$WORKER_NAME" <<- EOF
	echo "Copying files to Hadoop worker $i";
	scp $SSH_OPTIONS -i "$AWS_KEY_PAIR_NAME.pem" -r hadoop/* "ubuntu@$WORKER_IP:~";
	ssh $SSH_OPTIONS -i "$AWS_KEY_PAIR_NAME.pem" -t "ubuntu@$WORKER_IP" "export HADOOP_NAME=$WORKER_NAME; $(grep -E '(HADOOP|SSH)' < defaults) $(grep -E '(HADOOP|FLASK|MYSQL|MONGO)' < config) sudo -E ./setup.sh"
	EOF
    i=$(($i+1))
done

# Start screen for Hadoop master
echo 'Starting screen for Hadoop master'
screen-log "$HADOOP_MASTER" << EOF
echo 'Copying files to Hadoop master';
scp $SSH_OPTIONS -i "$AWS_KEY_PAIR_NAME.pem" -r hadoop/* "ubuntu@$HADOOP_MASTER_PUBLIC_IPV4:~";
ssh $SSH_OPTIONS -i "$AWS_KEY_PAIR_NAME.pem" "ubuntu@$HADOOP_MASTER_PUBLIC_IPV4" "export HADOOP_NAME=$HADOOP_MASTER; $(grep -E '(HADOOP|SSH)' < defaults) $(grep -E '(HADOOP|FLASK|MYSQL|MONGO)' < config) sudo -E ./setup.sh"
EOF

# Wait for MySQL and MongoDB servers to be set up
echo 'Waiting for MySQL and MongoDB servers to be set up...'
while screen -list | grep -q -E '(mysql_server|mongodb_server)'
do
    sleep 3
done

# Start screen for Flask server
echo 'Starting screen for Flask server'
screen-log flask_server << EOF
echo 'Copying files to Flask server'
scp $SSH_OPTIONS -i "$AWS_KEY_PAIR_NAME.pem" -r flask_server/* "ubuntu@$FLASK_PUBLIC_IPV4:~"
ssh $SSH_OPTIONS -i "$AWS_KEY_PAIR_NAME.pem" "ubuntu@$FLASK_PUBLIC_IPV4" "echo '$(cat hadoop/id_rsa.pub)' | sudo tee -a ~/.ssh/authorized_keys >/dev/null; $(grep -E '(MYSQL|MONGO)' < defaults) $(grep -E '(MYSQL|MONGO)' < credentials) $(grep -E '(MYSQL|MONGO)' < config) sudo -E ./setup.sh"
EOF

# Wait for Hadoop workers to be set up (maximum 60 seconds)
echo 'Waiting for Hadoop workers to be set up...'
i=0
while [[ $i -lt 20 ]] && screen -list | grep -q "$HADOOP_WORKER_PREFIX"
do
    sleep 3
    i=$(($i+1))
done

# Wait for Hadoop master to be set up
echo 'Waiting for Hadoop master to be set up...'
while screen -list | grep -q "$HADOOP_MASTER"
do
    sleep 3
done

# Wait for Flask server to be set up
echo 'Waiting for Flask server to be set up...'
while screen -list | grep -q flask_server
do
    sleep 3
done

# Return Flask DNS
echo "Flask server is running at http://$FLASK_PUBLIC_DNS"

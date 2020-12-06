#!/bin/bash

# Log function for debugging purposes
log() {
    # Read input from arguments or stdin
    if [ -z "$1" ]; then read -d '' input; else input="$1"; fi
    # Indent input by 2 spaces
    echo "$input" | sed 's/^/  /'
}

echo 'Setting up Hadoop instance'

# Install Java
echo 'Installing Java'
sudo apt-get update -qq >/dev/null
sudo DEBIAN_FRONTEND=noninteractive apt-get install openjdk-8-jdk -qq >/dev/null

# Install Hadoop dependencies
echo 'Installing Hadoop dependencies'
# Download numpy (pyspark.ml dependency)
sudo DEBIAN_FRONTEND=noninteractive apt-get install python3-numpy -qq >/dev/null
# # Download nltk (for tokenizing words)
# sudo DEBIAN_FRONTEND=noninteractive apt-get install python3-nltk -qq >/dev/null
# sudo python3 -c 'import nltk; nltk.download("punkt", download_dir="/usr/share/nltk_data")'

# Update hosts file
if [ -z "$HADOOP_MASTER_PRIVATE_IPV4" ]
then
    echo 'Enter private IP address of Hadoop master:'
    read HADOOP_MASTER_PRIVATE_IPV4
fi
if [ -z "$HADOOP_MASTER" ]
then
    echo 'Enter name of Hadoop master:'
    read HADOOP_MASTER
fi
if [ -z "$HADOOP_NUM_WORKERS" ]
then
    echo 'Enter number of Hadoop workers:'
    read HADOOP_NUM_WORKERS
fi
if [ -z "$HADOOP_WORKERS_PRIVATE_IPV4" ]
then
    echo 'Enter private IP addresses of Hadoop workers:'
    read HADOOP_WORKERS_PRIVATE_IPV4
fi
if [ -z "$HADOOP_WORKERS" ]
then
    echo 'Enter names of Hadoop workers:'
    read HADOOP_WORKERS
fi
echo 'Updating hosts file'
HOSTS="$HADOOP_MASTER_PRIVATE_IPV4 $HADOOP_MASTER"
i=0
while [[ $i -lt "$HADOOP_NUM_WORKERS" ]]
do
    HOSTS+="\n$(cut -d' ' -f$(($i+1)) <<< $HADOOP_WORKERS_PRIVATE_IPV4) $(cut -d' ' -f$(($i+1)) <<< $HADOOP_WORKERS)"
    i=$(($i+1))
done
sudo sed -i "/^127.0.0.1 localhost/a $HOSTS" /etc/hosts
# Print /etc/hosts for verification
echo 'Hosts file:'
cat /etc/hosts | log

# Update hostname
if [ -z "$HADOOP_NAME" ]
then
    echo 'Enter name of Hadoop instance:'
    read HADOOP_NAME
fi
echo 'Updating hostname'
sudo echo "$HADOOP_NAME" > /etc/hostname
# Print /etc/hostname for verification
echo 'Hostname:'
cat /etc/hostname | log

# Modify swappiness
echo 'Modifying swappiness'
sudo sysctl vm.swappiness=10 | log

# Unzip Hadoop
echo 'Unzipping Hadoop'
tar zxf hadoop-3.3.0.tar.gz
rm hadoop-3.3.0.tar.gz

# Configure workers
echo 'Configuring workers'
echo "$HADOOP_WORKERS" > hadoop-3.3.0/etc/hadoop/workers
# Print workers for verification
echo 'Hadoop workers:'
cat hadoop-3.3.0/etc/hadoop/workers | log

# Configure hadoop-env.sh
echo 'Configuring hadoop-env.sh'
sed -i "s/# export JAVA_HOME=.*/export\ JAVA_HOME=\/usr\/lib\/jvm\/java-8-openjdk-amd64/g" hadoop-3.3.0/etc/hadoop/hadoop-env.sh

# Configure core-site.xml
echo 'Configuring core-site.xml'
cat << EOF > hadoop-3.3.0/etc/hadoop/core-site.xml
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!-- Site specific core configuration properties -->
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://$HADOOP_MASTER:9000</value>
    </property>
</configuration>
EOF

# Configure hdfs-site.xml
echo 'Configuring hdfs-site.xml'
cat << EOF > hadoop-3.3.0/etc/hadoop/hdfs-site.xml
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!-- Site specific HDFS configuration properties -->
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>3</value>
    </property>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>file:/mnt/hadoop/namenode</value>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>file:/mnt/hadoop/datanode</value>
    </property>
</configuration>
EOF

# Configure yarn-site.xml
echo 'Configuring yarn-site.xml'
cat << EOF > hadoop-3.3.0/etc/hadoop/yarn-site.xml
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!-- Site specific YARN configuration properties -->
<configuration>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
        <description>Tell NodeManagers that there will be an auxiliary service called mapreduce.shuffle that they need to implement</description>
    </property>
    <property>
        <name>yarn.nodemanager.aux-services.mapreduce_shuffle.class</name>
        <value>org.apache.hadoop.mapred.ShuffleHandler</value>
        <description>A class name as a means to implement the service</description>
    </property>
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>$HADOOP_MASTER</value>
    </property>
</configuration>
EOF

# Configure mapred-site.xml
echo 'Configuring mapred-site.xml'
cat << EOF > hadoop-3.3.0/etc/hadoop/mapred-site.xml
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!-- Site specific MapReduce configuration properties -->
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
        <description>Use YARN to tell MapReduce that it will run as a YARN application</description>
    </property>
    <property>
        <name>yarn.app.mapreduce.am.env</name>
        <value>HADOOP_MAPRED_HOME=/opt/hadoop-3.3.0/</value>
    </property>
    <property>
        <name>mapreduce.map.env</name>
        <value>HADOOP_MAPRED_HOME=/opt/hadoop-3.3.0/</value>
    </property>
    <property>
        <name>mapreduce.reduce.env</name>
        <value>HADOOP_MAPRED_HOME=/opt/hadoop-3.3.0/</value>
    </property>
</configuration>
EOF

# Unzip Spark
echo 'Unzipping Spark'
tar zxf spark-3.0.1-bin-hadoop3.2.tgz
rm spark-3.0.1-bin-hadoop3.2.tgz

# Configure spark-env.sh
echo 'Configuring spark-env.sh'
cp spark-3.0.1-bin-hadoop3.2/conf/spark-env.sh.template spark-3.0.1-bin-hadoop3.2/conf/spark-env.sh
cat << EOF > spark-3.0.1-bin-hadoop3.2/conf/spark-env.sh
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export HADOOP_HOME=/opt/hadoop-3.3.0
export SPARK_HOME=/opt/spark-3.0.1-bin-hadoop3.2
export SPARK_CONF_DIR=\${SPARK_HOME}/conf
export HADOOP_CONF_DIR=\${HADOOP_HOME}/etc/hadoop
export YARN_CONF_DIR=\${HADOOP_HOME}/etc/hadoop
export SPARK_EXECUTOR_CORES=1
export SPARK_EXECUTOR_MEMORY=2G
export SPARK_DRIVER_MEMORY=1G
export PYSPARK_PYTHON=python3
EOF

# Configure slaves
echo 'Configuring slaves'
echo "$HADOOP_WORKERS" >> spark-3.0.1-bin-hadoop3.2/conf/slaves
# Print slaves for verification
echo 'Spark slaves:'
cat spark-3.0.1-bin-hadoop3.2/conf/slaves | log

# Create hadoop user
echo 'Creating hadoop user'
sudo useradd -s /bin/bash -m -U hadoop

# Grant sudo rights to hadoop user
echo 'Granting sudo rights to hadoop user'
echo "hadoop ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/90-hadoop >/dev/null

# Register Hadoop cluster SSH key
echo 'Registering Hadoop cluster SSH key'
cat id_rsa.pub >> ~/.ssh/authorized_keys
sudo cp id_rsa ~/.ssh
sudo chown ubuntu:ubuntu ~/.ssh/id_rsa
mkdir /home/hadoop/.ssh
cat id_rsa.pub >> /home/hadoop/.ssh/authorized_keys
sudo cp id_rsa /home/hadoop/.ssh
sudo chown -R hadoop:hadoop /home/hadoop/.ssh
rm id_rsa*

# Add scripts to hadoop user HOME
echo 'Adding scripts to hadoop user HOME'
mv scripts/* /home/hadoop
sudo chown hadoop:hadoop /home/hadoop/*

# Install Hadoop
echo 'Installing Hadoop'
sudo mv hadoop-3.3.0 /opt/
sudo chown -R hadoop:hadoop /opt/hadoop-3.3.0

# Add Hadoop to hadoop user PATH
echo 'Adding Hadoop to hadoop user PATH'
echo 'PATH=/opt/hadoop-3.3.0/bin:/opt/hadoop-3.3.0/sbin:$PATH' >> /home/hadoop/.profile

# Install Spark
echo 'Installing Spark'
sudo mv spark-3.0.1-bin-hadoop3.2 /opt/
sudo chown -R hadoop:hadoop /opt/spark-3.0.1-bin-hadoop3.2

# Add Spark to hadoop user PATH
echo 'Adding Spark to hadoop user PATH'
echo 'PATH=/opt/spark-3.0.1-bin-hadoop3.2/bin:/opt/spark-3.0.1-bin-hadoop3.2/sbin:$PATH' >> /home/hadoop/.profile

# Create Hadoop drive
echo 'Creating Hadoop drive'
if [[ "$HADOOP_NAME" != "$HADOOP_MASTER" ]]
then
    sudo mkdir -p /mnt/hadoop/datanode/
    sudo chown -R hadoop:hadoop /mnt/hadoop/datanode/
else
    sudo mkdir -p /mnt/hadoop/namenode/
    sudo chown -R hadoop:hadoop /mnt/hadoop/namenode/

    # Format namenode
    echo 'Formatting namenode'
    sudo -i -u hadoop bash -c 'hdfs namenode -format -force'

    # Create logs folder
    echo 'Creating logs folder'
    mkdir logs

    # Create cron job for running analytics
    echo 'Creating cron job for running analytics'
    sudo su - ubuntu -c '(crontab -l 2>/dev/null; echo "0 0 * * * ~/ingest_data.sh; ~/run_analytics.sh 2>&1 >> ~/logs/cron.log") | crontab -'
    echo 'Cron tab:'
    sudo su - ubuntu -c 'crontab -l' | log

    # # Download Sqoop
    # echo 'Downloading Sqoop'
    # wget -q https://apachemirror.sg.wuchna.com/sqoop/1.4.7/sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz

    # # Unzip Sqoop
    # echo 'Unzipping Hadoop'
    # tar zxf sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz
    # rm sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz

    # # Configure Sqoop environment
    # echo 'Configuring Sqoop environment'
    # cp sqoop-1.4.7.bin__hadoop-2.6.0/conf/sqoop-env-template.sh sqoop-1.4.7.bin__hadoop-2.6.0/conf/sqoop-env.sh
    # sed -i "s/#export HADOOP_COMMON_HOME=.*/export HADOOP_COMMON_HOME=\/opt\/hadoop-3.3.0/g" sqoop-1.4.7.bin__hadoop-2.6.0/conf/sqoop-env.sh
    # sed -i "s/#export HADOOP_MAPRED_HOME=.*/export HADOOP_MAPRED_HOME=\/opt\/hadoop-3.3.0/g" sqoop-1.4.7.bin__hadoop-2.6.0/conf/sqoop-env.sh

    # # Install Sqoop
    # echo 'Installing Sqoop'
    # sudo mv sqoop-1.4.7.bin__hadoop-2.6.0 /opt/sqoop-1.4.7
    # sudo chown -R hadoop:hadoop /opt/sqoop-1.4.7

    # # Download Sqoop dependencies
    # echo 'Downloading Sqoop dependencies'
    # wget -q https://repo1.maven.org/maven2/commons-lang/commons-lang/2.6/commons-lang-2.6.jar
    # sudo DEBIAN_FRONTEND=noninteractive apt-get install libmysql-java -qq >/dev/null

    # # Install Sqoop dependencies
    # echo 'Installing Sqoop dependencies'
    # sudo mv commons-lang-2.6.jar /opt/sqoop-1.4.7/lib/
    # sudo ln -snf /usr/share/java/mysql-connector-java.jar /opt/sqoop-1.4.7/lib/mysql-connector-java.jar

    # # Add Sqoop to hadoop user PATH
    # echo 'Adding Sqoop to hadoop user PATH'
    # echo 'PATH=/opt/sqoop-1.4.7/bin:$PATH' >> /home/hadoop/.profile
fi

# Save Hadoop configuration
echo 'Saving Hadoop configuration'
cat << EOF >> config
export SSH_OPTIONS='$SSH_OPTIONS';
export MYSQL_PRIVATE_IPV4=$MYSQL_PRIVATE_IPV4;
export MONGO_PRIVATE_IPV4=$MONGO_PRIVATE_IPV4;
export FLASK_PRIVATE_IPV4=$FLASK_PRIVATE_IPV4;
export FLASK_PUBLIC_DNS=$FLASK_PUBLIC_DNS;
export HADOOP_NAME=$HADOOP_NAME;
export HADOOP_MASTER=$HADOOP_MASTER;
export HADOOP_WORKERS='$HADOOP_WORKERS';
export HADOOP_NUM_WORKERS='$HADOOP_NUM_WORKERS';
export HADOOP_MASTER_PRIVATE_IPV4=$HADOOP_MASTER_PRIVATE_IPV4;
export HADOOP_WORKERS_PRIVATE_IPV4='$HADOOP_WORKERS_PRIVATE_IPV4';
EOF

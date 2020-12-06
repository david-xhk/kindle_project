#!/bin/bash

# Custom function for screen
screen-log() {
    script="$(mktemp)"
    cat > $script
    chmod u+x $script
    name="$1"
    logfile="logs/$name.log"
    [ -e "$logfile" ] && rm "$logfile"
    screen -dmS "$name" $script
    screen -S "$name" -X logfile "$logfile"
    screen -S "$name" -X logfile flush 1
    screen -S "$name" -X log
    rm $script
}

# Custom function for collating files
collate() {
    temp="$(mktemp)"
    dir="$1"
    filetype="$2"
    outfile="$1.$2"
    cat $1/* > $temp
    rm -r $1
    mv $temp $outfile
}

# Load Hadoop configuration
echo 'Loading Hadoop configuration'
source config

echo 'Running analytics'

# Run start script
sudo -i -u hadoop bash -c './start.sh'

# Preparing output folders
echo 'Preparing output folders'
rm -rf output; mkdir output
sudo -i -u hadoop bash -c 'rm -rf output; mkdir output'

# Submit tf-idf job
echo 'Submitting tf-idf job'
screen-log tfidf << EOF
sudo -i -u hadoop bash -c 'spark-submit --master yarn tfidf.py'
EOF

# Submit Pearson job
echo 'Submitting Pearson job'
screen-log pearson << EOF
sudo -i -u hadoop bash -c 'spark-submit --master yarn pearson.py'
EOF

# Wait for jobs to finish
echo 'Waiting for jobs to finish...'
while screen -list | grep -q -E '(tfidf|pearson)'
do
    sleep 3
done

# Collate results
echo 'Collating results'
sudo -i -u hadoop bash -c 'hdfs dfs -get /output/* output'
sudo mv /home/hadoop/output/* output
sudo chown -R ubuntu:ubuntu output
collate output/tfidf json
collate output/pearson/result txt
collate output/pearson/data json

# Run stop script
sudo -i -u hadoop bash -c './stop.sh'

# Send tf-idf results to MongoDB server
echo 'Sending tf-idf results to MongoDB server'
scp $SSH_OPTIONS output/tfidf.json "ubuntu@$MONGO_PRIVATE_IPV4:~"
ssh $SSH_OPTIONS "ubuntu@$MONGO_PRIVATE_IPV4" "./import_tfidf.sh"

# Send Pearson results to Flask server
echo 'Sending Pearson results to Flask server'
scp $SSH_OPTIONS -r output/pearson "ubuntu@$FLASK_PRIVATE_IPV4:~/app/static"

echo
echo "TF-IDF results are available at http://$FLASK_PUBLIC_DNS/tfidf/<reviewId>"
echo "Pearson correlation can be found at http://$FLASK_PUBLIC_DNS/pearson"
echo "Pearson correlation data can be found at http://$FLASK_PUBLIC_DNS/pearson/data"

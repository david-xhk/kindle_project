
source ipv4.conf

scp -i ec2-key.pem -r $1 ubuntu@${!1}:~


source ipv4.conf

ssh -i ec2-key.pem ubuntu@${!1}

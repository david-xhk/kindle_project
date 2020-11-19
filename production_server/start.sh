
cd ~/production_server/root

# start the server on port 80 in the background with no hangup and pipe all outputs to output.log
nohup python3 -u -m http.server 80 > ~/production_server/output.log &
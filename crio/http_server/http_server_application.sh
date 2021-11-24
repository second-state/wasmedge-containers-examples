#!/bin/bash
sudo crictl pull docker.io/avengermojo/http_server:with-wasm-annotation
if [ -f sandbox_config.json ]
then 
    rm -rf sandbox_config.json
fi
if [ -f container_http_server.json ]
then 
    rm -rf container_http_server.json
fi
wget https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/crio/sandbox_config.json
wget https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/crio/http_server/container_http_server.json
echo -e "Creating POD ..."
POD_ID=$(sudo crictl runp sandbox_config.json)
echo -e "POD_ID: $POD_ID"
CONTAINER_ID=$(sudo crictl create $POD_ID container_http_server.json sandbox_config.json)
echo -e "CONTAINER_ID: $CONTAINER_ID"
sudo crictl start $CONTAINER_ID
sudo crictl ps -a
echo -e "Sleeping for 10 seconds"
sleep 10
echo -e "Awake again"
sudo crictl ps -a
echo -e "Checking logs ...\n\n"
sudo crictl logs $CONTAINER_ID
echo -e "\n\nTesting ...\n\n"
HTTP_IP=`sudo crictl inspect $CONTAINER_ID | grep IP.0 | cut -d: -f 2 | cut -d'"' -f 2`
echo -e "IP address is $HTTP_IP \n\n"
curl -d "name=WasmEdge" -X POST http://$HTTP_IP:1234
# Clean up
echo -e "Cleaning up ..."
rm -rf sandbox_config.json
rm -rf container_http_server.json
echo -e "Done!"

#!/bin/bash
export WASM_IMAGE=docker.io/wasmedge/example-wasi-http
export WASM_IMAGE_TAG=latest
export CONFIG_FOLDER=$( dirname -- "$0"; )
export SANDBOX_CONFIG_NAME=sandbox_config.json
export CONTAINER_CONFIG_NAME=container_http_server.json

for opt in "$@"; do
  case $opt in
    --tag=*)
      export WASM_IMAGE_TAG="${opt#*=}"
      shift
      ;;
    --config=*)
      export CONTAINER_CONFIG_NAME="${opt#*=}"
      shift
      ;;
    *)
      ;;
  esac
done

echo -e "Pull images"
sudo crictl pull $WASM_IMAGE:$WASM_IMAGE_TAG

echo -e "Copy configuration files"
if [ -f $SANDBOX_CONFIG_NAME ]
then 
    rm -rf $SANDBOX_CONFIG_NAME
fi
if [ -f $CONTAINER_CONFIG_NAME ]
then 
    rm -rf $CONTAINER_CONFIG_NAME
fi
cp $CONFIG_FOLDER/../$SANDBOX_CONFIG_NAME ./
cp $CONFIG_FOLDER/$CONTAINER_CONFIG_NAME ./

echo -e "Creating POD ..."
POD_ID=$(sudo crictl runp $SANDBOX_CONFIG_NAME)

echo -e "POD_ID: $POD_ID"
CONTAINER_ID=$(sudo crictl create $POD_ID $CONTAINER_CONFIG_NAME $SANDBOX_CONFIG_NAME)

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
rm -rf $SANDBOX_CONFIG_NAME
rm -rf $CONTAINER_CONFIG_NAME
echo -e "Done!"

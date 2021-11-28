#!/bin/bash

kubectrl apply -f k8s-http_server.yaml

HOST_IP=`kubectl get pod --all-namespaces -o wide | grep http-server | tr -s ' '  | cut -d ' ' -f  9`

echo -e "Server is running at $HOST_IP"

echo -e "\n\nTesting\n\n"
curl -d "name=WasmEdge" -X POST http://$HOST_IP:1234
echo -e "\n\nFinished\n\n"
echo -e "Done!"

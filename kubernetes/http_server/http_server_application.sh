#!/bin/bash

export KUBERNETES_PROVIDER=local


cluster/kubectl run --restart=Never http-server --image=avengermojo/http-server:with-wasm-annotation --annotations="module.wasm.image/variant=compat" --overrides='{"kind":"Pod", "apiVersion":"v1", "spec": {"hostNetwork": true}}'

echo -e "Pulling image from the docker hub..."
sleep 10

HOST_IP=`cluster/kubectl get pod --all-namespaces -o wide | grep http-server | tr -s ' '  | cut -d ' ' -f  9`

echo -e "Server is running at $HOST_IP"

echo -e "\n\nTesting\n\n"
curl -d "name=WasmEdge" -X POST http://$HOST_IP:1234
echo -e "\n\nFinished\n\n"
echo -e "Done!"

#!/bin/bash

export KUBERNETES_PROVIDER=local

cluster/kubectl.sh config set-cluster local --server=https://localhost:6443 --certificate-authority=/var/run/kubernetes/server-ca.crt
cluster/kubectl.sh config set-credentials myself --client-key=/var/run/kubernetes/client-admin.key --client-certificate=/var/run/kubernetes/client-admin.crt
cluster/kubectl.sh config set-context local --cluster=local --user=myself
cluster/kubectl.sh config use-context local
cluster/kubectl.sh cluster-info


cluster/kubectl run --restart=Never http-server --image=avengermojo/http-server:with-wasm-annotation --annotations="module.wasm.image/variant=compat" --overrides='{"kind":"Pod", "apiVersion":"v1", "spec": {"hostNetwork": true}}'

echo -e "Pulling image from the docker hub..."
sleep 10

HOST_IP=`cluster/kubectl get pod --all-namespaces -o wide | grep http-server | tr -s ' '  | cut -d ' ' -f  9`

echo -e "Server is running at $HOST_IP"

echo -e "\n\nTesting\n\n"
curl -d "name=WasmEdge" -X POST http://$HOST_IP:1234
echo -e "\n\nFinished\n\n"
echo -e "Done!"

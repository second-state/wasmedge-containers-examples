#!/bin/bash

export KUBERNETES_PROVIDER=local
export CONFIG_FOLDER=$( dirname -- "$0"; )
export CONFIG_NAME=k8s-http_server.yaml

sudo ./kubernetes/cluster/kubectl.sh config set-cluster local --server=https://localhost:6443 --certificate-authority=/var/run/kubernetes/server-ca.crt
sudo ./kubernetes/cluster/kubectl.sh config set-credentials myself --client-key=/var/run/kubernetes/client-admin.key --client-certificate=/var/run/kubernetes/client-admin.crt
sudo ./kubernetes/cluster/kubectl.sh config set-context local --cluster=local --user=myself
sudo ./kubernetes/cluster/kubectl.sh config use-context local
sudo ./kubernetes/cluster/kubectl.sh

sudo ./kubernetes/cluster/kubectl.sh cluster-info

if [ -f "$CONFIG_NAME" ]
then
    rm -rf "$CONFIG_NAME"
fi
cp "$CONFIG_FOLDER"/"$CONFIG_NAME" ./

sudo ./kubernetes/cluster/kubectl.sh apply -f "$CONFIG_NAME"

echo -e "Pulling image from the docker hub...\n"
sleep 60

sudo ./kubernetes/cluster/kubectl.sh get pod --all-namespaces -o wide

echo -e "\n\nTesting\n\n"
curl -d "name=WasmEdge" -X POST http://127.0.0.1:1234
echo -e "\n\nFinished\n\n"

# Clean up
echo -e "Cleaning up ...\n"
rm -rf "$CONFIG_NAME"
echo -e "Done!\n"

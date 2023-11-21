#!/bin/bash
set -x # Enable verbose for the debug information
export KUBERNETES_PROVIDER=local
export WASM_IMAGE=docker.io/wasmedge/example-wasi
export WASM_IMAGE_TAG=latest
export VARIANT=compat-smart

sudo ./kubernetes/cluster/kubectl.sh config set-cluster local --server=https://localhost:6443 --certificate-authority=/var/run/kubernetes/server-ca.crt
sudo ./kubernetes/cluster/kubectl.sh config set-credentials myself --client-key=/var/run/kubernetes/client-admin.key --client-certificate=/var/run/kubernetes/client-admin.crt
sudo ./kubernetes/cluster/kubectl.sh config set-context local --cluster=local --user=myself
sudo ./kubernetes/cluster/kubectl.sh config use-context local
sudo ./kubernetes/cluster/kubectl.sh

sudo ./kubernetes/cluster/kubectl.sh cluster-info
sudo ./kubernetes/cluster/kubectl.sh run -i --restart=Never wasi-demo \
	--image=$WASM_IMAGE:$WASM_IMAGE_TAG \
	--annotations="module.wasm.image/variant=$VARIANT" \
	--overrides='{"kind":"Pod", "apiVersion":"v1", "spec": {"hostNetwork": true}}' /wasi_example_main.wasm 50000000

echo -e "Wait 60s"
sleep 60

sudo ./kubernetes/cluster/kubectl.sh get pod --all-namespaces -o wide

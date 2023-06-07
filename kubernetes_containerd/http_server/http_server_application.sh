#!/bin/bash
set -x # Enable verbose for the debug information
export KUBERNETES_PROVIDER=local
export WASM_IMAGE=docker.io/wasmedge/example-wasi-http
export WASM_IMAGE_TAG=latest

for opt in "$@"; do
  case $opt in
    --tag=*)
      export WASM_IMAGE_TAG="${opt#*=}"
      shift
      ;;
    *)
      ;;
  esac
done

sudo ./kubernetes/cluster/kubectl.sh config set-cluster local --server=https://localhost:6443 --certificate-authority=/var/run/kubernetes/server-ca.crt
sudo ./kubernetes/cluster/kubectl.sh config set-credentials myself --client-key=/var/run/kubernetes/client-admin.key --client-certificate=/var/run/kubernetes/client-admin.crt
sudo ./kubernetes/cluster/kubectl.sh config set-context local --cluster=local --user=myself
sudo ./kubernetes/cluster/kubectl.sh config use-context local
sudo ./kubernetes/cluster/kubectl.sh

sudo ./kubernetes/cluster/kubectl.sh cluster-info
sudo ./kubernetes/cluster/kubectl.sh run --restart=Never http-server \
	--image=$WASM_IMAGE:$WASM_IMAGE_TAG \
	--overrides='{"kind":"Pod", "apiVersion":"v1", "spec": {"hostNetwork": true}}'

echo -e "Wait 60s"
sleep 60

sudo ./kubernetes/cluster/kubectl.sh get pod --all-namespaces -o wide

echo -e "\n\nTesting\n\n"
curl -d "name=WasmEdge" -X POST http://127.0.0.1:1234
echo -e "\n\nFinished\n\n"
echo -e "Done!"


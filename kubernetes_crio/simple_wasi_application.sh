#!/bin/bash
export KUBERNETES_PROVIDER=local
export WASM_IMAGE=docker.io/wasmedge/example-wasi
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
# Check 
sudo crictl pods
sudo ./kubernetes/cluster/kubectl.sh cluster-info
sudo ./kubernetes/cluster/kubectl.sh run -it --rm --restart=Never wasi-demo \
	--image=$WASM_IMAGE:$WASM_IMAGE_TAG \
	/wasi_example_main.wasm 50000000

#!/bin/bash
set -x # Enable verbose for the debug information
export KUBERNETES_PROVIDER=local
export WASM_IMAGE=docker.io/hydai/wasm-image-demo
export WASM_IMAGE_TAG=tflite-bird-v1-plugin
export VARIANT=compat-smart
export CLUS_NAME=local
export CRED_NAME=myself
export SERVER=https://localhost:6443
export CERT_AUTH=/var/run/kubernetes/server-ca.crt
export CLIENT_KEY=/var/run/kubernetes/client-admin.key
export CLIENT_CERT=/var/run/kubernetes/client-admin.crt
export WASM_ENTRY=/wasmedge-wasinn-example-tflite-bird-image.wasm
export MODEL_NAME=lite-model_aiy_vision_classifier_birds_V1_3.tflite
export INPUT_PHOTO=bird.jpg

sudo ./kubernetes/cluster/kubectl.sh config set-cluster "$CLUS_NAME" --server="$SERVER" --certificate-authority="$CERT_AUTH"
sudo ./kubernetes/cluster/kubectl.sh config set-credentials $CRED_NAME --client-key="$CLIENT_KEY" --client-certificate="$CLIENT_CERT"
sudo ./kubernetes/cluster/kubectl.sh config set-context "$CLUS_NAME" --cluster="$CLUS_NAME" --user="$CRED_NAME"
sudo ./kubernetes/cluster/kubectl.sh config use-context "$CLUS_NAME"

sudo ./kubernetes/cluster/kubectl.sh cluster-info

sudo ./kubernetes/cluster/kubectl.sh run -i --restart=Never wasi-nn-demo \
	--image=$WASM_IMAGE:$WASM_IMAGE_TAG \
	--annotations="module.wasm.image/variant=$VARIANT" \
	--overrides='{"kind":"Pod", "apiVersion":"v1", "spec": {"hostNetwork": true}}' "$WASM_ENTRY" "$MODEL_NAME" "$INPUT_PHOTO"

echo -e "Wait 60s"
sleep 60

sudo ./kubernetes/cluster/kubectl.sh get pod --all-namespaces -o wide

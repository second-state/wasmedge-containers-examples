#!/bin/bash
set -x # Enable verbose for the debug information
export KUBERNETES_PROVIDER=local
export WASM_IMAGE=ghcr.io/second-state/runwasi-demo
export WASM_IMAGE_TAG=llama-simple
export VARIANT=compat-smart
export CLUS_NAME=local
export CRED_NAME=myself
export SERVER=https://localhost:6443
export CERT_AUTH=/var/run/kubernetes/server-ca.crt
export CLIENT_KEY=/var/run/kubernetes/client-admin.key
export CLIENT_CERT=/var/run/kubernetes/client-admin.crt


sudo ./kubernetes/cluster/kubectl.sh config set-cluster "$CLUS_NAME" --server="$SERVER" --certificate-authority="$CERT_AUTH"
sudo ./kubernetes/cluster/kubectl.sh config set-credentials $CRED_NAME --client-key="$CLIENT_KEY" --client-certificate="$CLIENT_CERT"
sudo ./kubernetes/cluster/kubectl.sh config set-context "$CLUS_NAME" --cluster="$CLUS_NAME" --user="$CRED_NAME"
sudo ./kubernetes/cluster/kubectl.sh config use-context "$CLUS_NAME"
sudo ./kubernetes/cluster/kubectl.sh cluster-info

sudo ./kubernetes/cluster/kubectl.sh run -i --restart=Never testggml --image=ghcr.io/captainvincent/runwasi-demo:llama-api-server --annotations="module.wasm.image/variant=compat-smart" --overrides='
{
  "apiVersion": "v1",
  "kind": "Pod",
  "metadata": {
    "name": "testggml"
  },
  "spec": {
    "hostNetwork": true,
    "containers": [
      {
        "name": "simple",
        "image": "ghcr.io/captainvincent/runwasi-demo:llama-api-server",
        "command": ["/app.wasm", "-p", "llama-2-chat"],
        "stdin": true,
        "tty": true,
        "env": [
          {
            "name": "WASMEDGE_PLUGIN_PATH",
            "value": "/opt/containerd/lib"
          },
          {
            "name": "WASMEDGE_WASINN_PRELOAD",
            "value": "default:GGML:CPU:/resource/llama-2-7b-chat.Q5_K_M.gguf"
          }
        ],
        "volumeMounts": [
          {
            "name": "plugins",
            "mountPath": "/opt/containerd/lib"
          },
          {
            "name": "model",
            "mountPath": "/resource"
          }
        ]
      }
    ],
    "volumes": [
      {
        "name": "plugins",
        "hostPath": {
          "path": "'"$HOME"'/.wasmedge/plugin/"
        }
      },
      {
        "name": "model",
        "hostPath": {
          "path": "'"$PWD"'"
        }
      }
    ]
  }
}'

echo -e "Wait 60s"
sleep 60

sudo ./kubernetes/cluster/kubectl.sh get pod --all-namespaces -o wide

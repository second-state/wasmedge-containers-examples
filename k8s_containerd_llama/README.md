# Run a WasmEdge LLAMA chat server app with Containerd over Kubernetes

## Environment

We use `Ubuntu 20.04 x86_64` in the following example.

## Install containerd, costomized crun, and WasmEdge

Reuse install script from other example, but use the experimental crun branch.

```bash
sed 's|https://github.com/containers/crun|-b enable-wasmedge-plugin https://github.com/second-state/crun|g' containerd/install.sh | bash
```

## Install k8s

Reuse install script from other example.

```bash
bash kubernetes_containerd/install.sh
```

## Run LLAMA chat server app
The [llama_server_application.sh](./llama_server_application.sh) script shows how to pull a WASM container image with WASI-NN-GGML plugin support from the Docker Hub, and then run it as a containerized application in Kubernetes.

```bash
bash k8s_containerd_llama/llama_server_application.sh
```

Test API service from other session

```bash
curl -X POST http://localhost:8080/v1/chat/completions -H 'accept:application/json' -H 'Content-Type: application/json' -d '{"messages":[{"role":"system", "content": "You are a helpful assistant."}, {"role":"user", "content": "Who is Robert Oppenheimer?"}], "model":"llama-2-chat"}' | jq .
```

Check output

```bash
```

[Learn more](https://wasmedge.org/book/en/kubernetes/kubernetes/kubernetes-containerd.html)

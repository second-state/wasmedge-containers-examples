# Run a WasmEdge WASI-NN app with Containerd over Kubernetes

## Environment

We use `Ubuntu 20.04 x86_64` in the following example.

## Install containerd, costomized crun, and WasmEdge

```bash
./install_containerd.sh
```

## Install k8s

```bash
./install_k8s.sh
```

## Run WASI-NN app
The [wasi_nn_application.sh](./wasi_nn_application.sh) script shows how to pull a WASM container image with WASI-NN plugin support from the Docker Hub, and then run it as a containerized application in Kubernetes.

```bash
./wasi_nn_application.sh
```

[Learn more](https://wasmedge.org/book/en/kubernetes/kubernetes/kubernetes-containerd.html)

# Run a WasmEdge simple demo app with Containerd over Kubernetes

You can use the containerd [install.sh](../containerd/install.sh) script to install containerd and `crun` on Ubuntu 20.04.


```bash
wget -qO- https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/containerd/install.sh | bash
```

Next, install Kubernetes using the [following script](install.sh).

```bash
wget -qO- https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/kubernetes_containerd/install.sh | bash
```

The [simple_wasi_application.sh](simple_wasi_application.sh) script shows how to pull [a WebAssembly application](../simple_wasi_app.md) from Docker Hub, and then run it as a containerized application in Kubernetes.

```bash
wget -qO- https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/kubernetes_containerd/simple_wasi_application.sh | bash
```

[Learn more](https://wasmedge.org/book/en/kubernetes/kubernetes/kubernetes-containerd.html)

# Run a WasmEdge HTTP server app with Containerd over Kubernetes

You can use the containerd [install.sh](../containerd/install.sh) script to install containerd and `crun` on Ubuntu 20.04.


```bash
wget -qO- https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/containerd/install.sh | bash
```

Next, install Kubernetes using the [following script](install.sh).

```bash
wget -qO- https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/kubernetes_containerd/install.sh | bash
```

The [http_server_application.sh](http_server_application.sh) script shows how to pull [a HTTP Server WebAssembly application](../../http_server_wasi_app.md) from Docker Hub, and then run it as a containerized application in Kubernetes.

```bash
wget -qO- https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/kubernetes_containerd/http_server/http_server_application.sh | bash
```

You should able to POST with curl and see results from the HTTP Server WebAssembly reply echo in the console. 

```bash
curl -d "name=WasmEdge" -X POST http://$HOST_IP:1234/post
echo name=WasmEdge
```

[Learn more](https://wasmedge.org/book/en/kubernetes/kubernetes/kubernetes-containerd.html)

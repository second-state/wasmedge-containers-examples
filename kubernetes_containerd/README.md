# Run WasmEdge http_server apps with Containerd over Kubernetes

## Quick start

You can use the Containerd [containerd_crun_install.sh](containerd_crun_install.sh) script to install Containerd and `crun` on Ubuntu 20.04.


```bash
wget -qO- https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/kubernetes_containerd/containerd_crun_install.sh | bash
```

Next, install Kubernetes using the [following script](install.sh).

```bash
wget -qO- https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/kubernetes_containerd/k8s_install.sh | bash
```

The sections below are step-by-step instructions for the above demo.

## Install Containerd
```bash

sudo apt update
export VERSION="1.5.7"
echo -e "Version: $VERSION"
echo -e "Installing libseccomp2 ..."
sudo apt install -y libseccomp2
echo -e "Installing wget"
sudo apt install -y wget

wget https://github.com/containerd/containerd/releases/download/v${VERSION}/cri-containerd-cni-${VERSION}-linux-amd64.tar.gz
wget https://github.com/containerd/containerd/releases/download/v${VERSION}/cri-containerd-cni-${VERSION}-linux-amd64.tar.gz.sha256sum
sha256sum --check cri-containerd-cni-${VERSION}-linux-amd64.tar.gz.sha256sum

sudo tar --no-overwrite-dir -C / -xzf cri-containerd-cni-${VERSION}-linux-amd64.tar.gz
sudo systemctl daemon-reload

# change containerd conf to use crun as default
sudo bash -c "containerd config default > /etc/containerd/config.toml"
wget https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/kubernetes_containerd/containerd_config.diff
sudo patch -d/ -p0 < containerd_config.diff
sudo systemctl start containerd
```

## Install WasmEdge

Use the [simple install script](https://github.com/WasmEdge/WasmEdge/blob/master/docs/install.md) to install WasmEdge.

```bash
wget -qO- https://raw.githubusercontent.com/WasmEdge/WasmEdge/master/utils/install.sh | bash -s -- -p /usr/local

```

## Build and install crun

You need a `crun` binary that supports WasmEdge. For now, the easiest approach is just built it yourself from source. First, let's make sure that `crun` dependencies are installed on your Ubuntu 20.04.
For other Linux distributions, please [see here](https://github.com/containers/crun#readme).

```bash
sudo apt update
sudo apt install -y make git gcc build-essential pkgconf libtool \
     libsystemd-dev libprotobuf-c-dev libcap-dev libseccomp-dev libyajl-dev 
     go-md2man libtool autoconf python3 automake

```

Next, configure, build, and install a `crun` binary with WasmEdge support.

```bash
wget https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/kubernetes_containerd/crun-patch.diff
git clone https://github.com/containers/crun
cd crun
git apply ../crun-patch.diff
./autogen.sh
./configure --with-wasmedge
make
sudo make install

```

## Install and start Kubernetes

Run the following commands from a terminal window.
It sets up Kubernetes for local development.

```bash
# Clone k8s
git clone https://github.com/kubernetes/kubernetes.git
cd kubernetes/
git checkout v1.22.4
cd ../
echo -e "Installing etcd"
# Install etcd with hack script in k8s
sudo apt-get install -y net-tools
sudo CGROUP_DRIVER=systemd CONTAINER_RUNTIME=remote CONTAINER_RUNTIME_ENDPOINT='unix:///var/run/containerd/containerd.sock' ./kubernetes/hack/install-etcd.sh
export PATH="/home/${USER}/kubernetes/third_party/etcd:${PATH}"
sudo cp -rp ./kubernetes/third_party/etcd/etcd* /usr/local/bin/
echo -e "Building and running k8s with CRI-O"
sudo apt-get install -y build-essential
sudo -b CGROUP_DRIVER=systemd CONTAINER_RUNTIME=remote CONTAINER_RUNTIME_ENDPOINT='unix:///var/run/containerd/containerd.sock' ./kubernetes/hack/local-up-cluster.sh
```

... ...
Local Kubernetes cluster is running. Press Ctrl-C to shut it down.
```
Do NOT close your terminal window. Kubernetes is running!

## Run a simple WebAssembly app

Finally, we can run a simple WebAssembly program using Kubernetes.
[A seperate article](../simple_wasi_app.md) explains how to compile, package, and publish the WebAssembly
program as a container image to Docker hub.
In this section, we will start from **another terminal window** and start using the cluster.

```bash
  export KUBERNETES_PROVIDER=local

  cluster/kubectl.sh config set-cluster local --server=https://localhost:6443 --certificate-authority=/var/run/kubernetes/server-ca.crt
  cluster/kubectl.sh config set-credentials myself --client-key=/var/run/kubernetes/client-admin.key --client-certificate=/var/run/kubernetes/client-admin.crt
  cluster/kubectl.sh config set-context local --cluster=local --user=myself
  cluster/kubectl.sh config use-context local
  cluster/kubectl.sh
# or
  export KUBECONFIG=/var/run/kubernetes/admin.kubeconfig

```

Let's check the status to make sure that the cluster is running.

```bash
sudo cluster/kubectl.sh cluster-info

# Expected output
Cluster "local" set.
User "myself" set.
Context "local" created.
Switched to context "local".
Kubernetes control plane is running at https://localhost:6443
CoreDNS is running at https://localhost:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

We can run the WebAssembly-based image from Docker Hub in the Kubernetes cluster.

```bash
sudo cluster/kubectl.sh run --restart=Never http-server --image=avengermojo/http-server:with-wasm-annotation --annotations="module.wasm.image/variant=compat" --overrides='{"kind":"Pod", "apiVersion":"v1", "spec": {"hostNetwork": true}}'
```

Then you can run the following curl request to validate the http_server is running

```bash
curl -d "name=WasmEdge" -X POST http://127.0.0.1:1234
echo: name=WasmEdge
```

That's it!

# Run WasmEdge http server with CRIO in Kubernetes

## Quick start

You can use the CRI-O [install.sh](../crio/install.sh) script to install CRI-O and `crun` on Ubuntu 20.04.

```bash
wget -qO- https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/crio/install.sh | bash
```

Next, install Kubernetes using the [following script](install.sh).

```bash
wget -qO- https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/kubernetes_crio/install.sh | bash
``` 

The [http_server_wasi_application.sh](http_server_wasi_application.sh) script shows how to pull [a HTTP Server WebAssembly application](../http_server_wasi_app.md) from Docker Hub, and then run it as a containerized application in Kubernetes.

```bash
wget -qO- https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/kubernetes_crio/http_server/http_server_application.sh | bash
```

You should able to POST with curl and see results from the HTTP Server WebAssembly reply echo in the console. 

```bash

curl -d "name=WasmEdge" -X POST http://$HOST_IP:1234/post
echo name=WasmEdge

```

The sections below are step-by-step instructions for the above demo.

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
   libsystemd-dev libprotobuf-c-dev libcap-dev libseccomp-dev libyajl-dev \
   go-md2man libtool autoconf python3 automake systemctl
```

Next, configure, build, and install a `crun` binary with WasmEdge support.

```bash
git clone https://github.com/containers/crun
cd crun
./autogen.sh
./configure --with-wasmedge
make
sudo make install
```

## Install CRI-O

Use the following commands to install CRI-O on your system.

```bash
export OS="xUbuntu_20.04"
export VERSION="1.21"
apt update
apt install -y libseccomp2 || sudo apt update -y libseccomp2
echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /" > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /" > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list

curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/Release.key | apt-key add -
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | apt-key add -

apt-get update
apt-get install criu libyajl2
apt-get install cri-o cri-o-runc cri-tools containernetworking-plugins
systemctl start crio
```

## Configure CRI-O

CRI-O uses the `runc` runtime by default and we need to configure it to use `crun` instead.
That is done by adding to two configuration files.

First, create a `/etc/crio/crio.conf` file and add the following lines as its content. It tells CRI-O to use `crun` by default.

```
[crio.runtime]
default_runtime = "crun"
```

The `crun` runtime is in turn defined in the `/etc/crio/crio.conf.d/01-crio-runc.conf` file.

```
[crio.runtime.runtimes.runc]
runtime_path = "/usr/lib/cri-o-runc/sbin/runc"
runtime_type = "oci"
runtime_root = "/run/runc"
# The above is the original content

# Add our crunw runtime here
[crio.runtime.runtimes.crun]
runtime_path = "/usr/bin/crun"
runtime_type = "oci"
runtime_root = "/run/crun"
```

Next, restart CRI-O to apply the configuration changes.

```bash
systemctl restart crio
```

## Install and start Kubernetes

Run the following commands from a terminal window.
It sets up Kubernetes for local development.

```bash
# Install go
wget https://golang.org/dl/go1.17.1.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.17.1.linux-amd64.tar.gz
source /home/${USER}/.profile

# Clone k8s
git clone https://github.com/kubernetes/kubernetes.git
cd kubernetes
git checkout v1.22.2
cd ../

# Install etcd with hack script in k8s
sudo CGROUP_DRIVER=systemd CONTAINER_RUNTIME=remote CONTAINER_RUNTIME_ENDPOINT='unix:///var/run/crio/crio.sock' ./hack/install-etcd.sh
export PATH="/home/${USER}/kubernetes/third_party/etcd:${PATH}"
sudo cp third_party/etcd/etcd* /usr/local/bin/

# After run the above command, you can find the following files: /usr/local/bin/etcd  /usr/local/bin/etcdctl  /usr/local/bin/etcdutl

# Build and run k8s with CRI-O
sudo apt-get install -y build-essential
sudo CGROUP_DRIVER=systemd CONTAINER_RUNTIME=remote CONTAINER_RUNTIME_ENDPOINT='unix:///var/run/crio/crio.sock' ./hack/local-up-cluster.sh

... ...
Local Kubernetes cluster is running. Press Ctrl-C to shut it down.
```

Do NOT close your terminal window. Kubernetes is running!

## Run a WebAssembly-based HTTP server app

Finally, we can run a HTTP service using Kubernetes.
[A seperate article](../../http_server_wasi_app.md) explains how to compile, package, and publish the WebAssembly
program as a container image to Docker hub.
In this section, we will start from **another terminal window** and start using the cluster.

```bash
export KUBERNETES_PROVIDER=local

sudo ./kubernetes/cluster/kubectl.sh config set-cluster local --server=https://localhost:6443 --certificate-authority=/var/run/kubernetes/server-ca.crt
sudo ./kubernetes/cluster/kubectl.sh config set-credentials myself --client-key=/var/run/kubernetes/client-admin.key --client-certificate=/var/run/kubernetes/client-admin.crt
sudo ./kubernetes/cluster/kubectl.sh config set-context local --cluster=local --user=myself
sudo ./kubernetes/cluster/kubectl.sh config use-context local
sudo ./kubernetes/cluster/kubectl.sh
```

Let's check the status to make sure that the cluster is running.

```bash
sudo ./kubernetes/cluster/kubectl.sh cluster-info

# Expected output
Cluster "local" set.
User "myself" set.
Context "local" created.
Switched to context "local".
Kubernetes control plane is running at https://localhost:6443
CoreDNS is running at https://localhost:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

Next, run the WebAssembly-based image from Docker Hub in the Kubernetes cluster.

```bash
sudo ./kubernetes/cluster/kubectl.sh run --restart=Never http-server --image=avengermojo/http-server:with-wasm-annotation --annotations="module.wasm.image/variant=compat" --overrides='{"kind":"Pod", "apiVersion":"v1", "spec": {"hostNetwork": true}}'
pod/http-server created
```

Check that the HTTP server WasmEdge application container is running.

```bash
sudo ./kubernetes/cluster/kubectl get pod --all-namespaces -o wide
NAMESPACE     NAME                            READY   STATUS    RESTARTS   AGE    IP           NODE    NOMINATED NODE   READINESS GATES
default       http-server                     1/1     Running   0          3s     127.0.0.1   k8s-1   <none>           <none>

```

Since we are running in the `hostNetwork` mode, the IP address for the WasmEdge
application container is always `127.0.0.1`.
You can check the HTTP server with request with the curl POST as following


```bash
curl -d "name=WasmEdge" -X POST http://127.0.0.1:1234
echo: name=WasmEdge

```

If you can see the server echo back the value you input, then that's it!

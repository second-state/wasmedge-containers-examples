# Run WasmEdge http server with CRIO in Kubernetes 

## Quick start

You can use the CRI-O [install.sh](../crio/install.sh) script to install CRI-O and `crun` on Ubuntu 20.04.

```bash
wget -qO- https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/crio/install.sh | bash
```

Next, install Kubernetes using the default Ubuntu deb but bug fixing needed in the following section.

The [http_server_wasi_application.sh](http_server_wasi_application.sh) script shows how to pull [a HTTP Server WebAssembly application](../../http_server_wasi_app.md) from Docker Hub, and then run it as a containerized application in Kubernetes.

```bash
wget -qO- https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/kubernetes/http_server_wasi_application.sh | bash
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

Using the default Ubuntu package to install the kubeadm, kubelet and kubectl together
in Ubuntu is a bit tricky. It has a dependencies conflict with the containernetworking-plugins.
https://github.com/containers/podman/issues/5296

So we need to edit the deb conflict out in order to finish the installation.

```bash

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl

```

Here you will face a conflict with the containernetworking-plugins, depends on
the crio version you installed before it maybe different from the example we are
using here, please change the version accordingly.
```bash

cp -a /var/cache/apt/archives/containernetworking-plugins_100%3a1.0.0-1_amd64.deb /tmp/
cd /tmp/
mkdir container
dpkg-deb -R containernetworking-plugins_100%3a1.0.0-1_amd64.deb container/
sed -i -e '/^Version:/s/$/~conflictfree/' -e '/^Conflicts: kubernetes-cni/d' container/DEBIAN/control
rm -f container/opt/cni/bin/*
sudo dpkg -b container/ containernetworking-plugins_100%3a1.0.0-1_amd64_custom.deb
sudo dpkg -i containernetworking-plugins_100%3a1.0.0-1_amd64_custom.deb
sudo apt update -qq && sudo apt install -qq -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl containernetworking-plugins

```


Once you get all the binary ready you should able to get their version and prepare
to use kudeadm to initilize the cluster.


```bash
wget -qO- https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/kubernetes/http_server/kubeadm-config.yaml | bash
sudo kubeadm init --config kubeadm-config.yaml

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join <$host_ip>:6443 --token xxxxxxxxxxxxxxxxxxxxxxx \
        --discovery-token-ca-cert-hash sha256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

For the completeness you can setup the pod network with e.g. funnel and adding
another node as worker.

## Run a simple WebAssembly app

Finally, we can run a HTTP Server WebAssembly program using Kubernetes.
[A seperate article](../http_server_wasi_app.md) explains how to compile, package, and publish the WebAssembly
program as a container image to Docker hub.
In this section, we will start from **another terminal window** and start using the cluster.


We can now run the WebAssembly-based image from Docker Hub in the Kubernetes cluster.
By applying the [yaml script](./k8s-http_server.yaml) and run it.

```bash
kubectl apply -f k8s-http_server.yaml
k8s-http_server.yaml

kubectl get pod --all-namespaces -o wide
NAMESPACE     NAME                            READY   STATUS    RESTARTS   AGE    IP           NODE    NOMINATED NODE   READINESS GATES
default       http-server                     1/1     Running   0          3s     <$host_ip>   k8s-1   <none>           <none>

```
Now you can check the http_server ip with request with the curl POST as following


```bash
curl -d "name=WasmEdge" -X POST http://<$host_ip>:1234
echo: name=WasmEdge

```

If you can see the server echo back the value you input, then that's it!

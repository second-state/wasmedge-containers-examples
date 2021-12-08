# Run WasmEdge http server with Containerd in Kubernetes

## Quick start

You can use the Containerd and WasmEdge [install.sh](../install.sh) script to 
install Containerd and `crun` on Ubuntu 20.04.

```bash
wget -qO- https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/containerd/install.sh | bash
```

Next, install Kubernetes using the default Ubuntu deb but bug fixing needed in the following section.

The [http_server_wasi_application.sh](http_server_wasi_application.sh) script 
shows how to pull [a HTTP Server WebAssembly application](../../http_server_wasi_app.md) 
from Docker Hub, and then run it as a containerized application in Kubernetes.

```bash
wget -qO- https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/kubernetes_crio/http_server_application.sh | bash
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

wget -q https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/containerd/http_server/full-cluster/crun_containerd.patch
git clone https://github.com/containers/crun
cd crun
git apply ../crun_containerd.patch
./autogen.sh
./configure --with-wasmedge
make
sudo make install
```

## Install Containerd

Use the following commands to install CRI-O on your system.

```bash

echo -e "Starting installation ..."
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
sudo systemctl start containerd

```

## Configure Containerd

Containerd uses the `runc` runtime by default as well and we need to configure it to use `crun` instead.
That is done by adding to two configuration files.

First, create a `/etc/containerd/config.toml` file by running

```bash

sudo mkdir -p /etc/containerd/
sudo containerd config default > /etc/containerd/config.toml

```

and add update the following lines as its content.

```bash
...
    [plugins."io.containerd.grpc.v1.cri".containerd]
      default_runtime_name = "crun"
...

```
Replace the runc with crun

```
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
          base_runtime_spec = ""
          container_annotations = []
          pod_annotations = []
.........................................................................
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.crun]
          base_runtime_spec = ""
          container_annotations = []
          pod_annotations = ["*.wasm.*", "wasm.*", "module.wasm.image/*", "*.module.wasm.image", "module.wasm.image/variant.*"]

...
          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
            BinaryName = "runc"
.........................................................................
          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.crun.options]
            BinaryName = "crun"
...


  [plugins."io.containerd.runtime.v1.linux"]
    no_shim = false
    runtime = "runc"
.........................................................................
  [plugins."io.containerd.runtime.v1.linux"]
    no_shim = false
    runtime = "crun"

```

Next, restart Containerd to apply the configuration changes.

```bash
systemctl restart containerd
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
sudo apt --fix-missing update
sudo apt-mark hold kubelet kubeadm kubectl containernetworking-plugins

```


Once you get all the binary ready you should able to get their version and prepare
to use kudeadm to initilize the cluster.


```bash

modprobe br_netfilter overlay
echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables
echo 1 > /proc/sys/net/bridge/bridge-nf-call-ip6tables
echo 1 > /proc/sys/net/ipv4/ip_forward

sudo kubeadm init --pod-network-cidr=10.244.0.0/16

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
another node as worker. You can now create another terminal and run the following

```bash

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

kubectl taint nodes --all node-role.kubernetes.io/master-

```

## Run a simple WebAssembly app

Finally, we can run a HTTP Server WebAssembly program using Kubernetes.

There is also one more bug in the crun https://github.com/containers/crun/issues/798
waiting to merge back to the main tree or you can just add the following like in
src/libcrun/container.c yourself to make the containerd shim model.

```
...
  @container_init (void *args, char *notify_socket, int sync_socket, libcrun_error_ ...
  ...

  if (entrypoint_args->exec_func)
    {

+       execv (exec_path, (char *[]){ NULL });
      ret = entrypoint_args->exec_func (entrypoint_args->container, entrypoint_args->exec_func_arg, exec_path,
                                        def->process->args);
      if (ret != 0)
  ...
```

[A seperate article](../../../kubernetes_crio/http_server_wasi_app.md) explains how to compile, package, and publish the WebAssembly
program as a container image to Docker hub.
In this section, we will start from **another terminal window** and start using the cluster.

We can now run the WebAssembly-based image from Docker Hub in the Kubernetes cluster.
By applying the [yaml script](../../../kubernetes_crio/http_server/full-cluster/k8s-http_server.yaml) and run it.

```bash
kubectl apply -f k8s-http_server.yaml
k8s-http_server.yaml

mubectl get pod --all-namespaces -o wide
NAMESPACE     NAME                            READY   STATUS    RESTARTS   AGE    IP           NODE    NOMINATED NODE   READINESS GATES
default       http-server                     1/1     Running   0          3s     <$host_ip>   k8s-1   <none>           <none>

```
Now you can check the http_server ip with request with the curl POST as following


```bash
curl -d "name=WasmEdge" -X POST http://<$host_ip>:1234
echo: name=WasmEdge

```

If you can see the server echo back the value you input, then that's it!

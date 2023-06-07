# 在 K8s 中并列运行  WasmEdge 应用与 Docker 容器

## 快速开始

你可以在 Ubuntu 20.04 上使用 CRI-O [install.sh](../crio/install.sh) 脚本安装 CRI-O 并运行 `crun` 。

```bash
wget -qO- https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/crio/install.sh | bash
```

接下来，使用[下面脚本](install.sh)安装 Kubernetes。

```bash
wget -qO- https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/kubernetes_crio/install.sh | bash
``` 

[simple_wasi_application.sh](simple_wasi_application.sh) 脚本显示如何从 Docker Hub 拉取 [一个 WebAssembly 应用](../simple_wasi_app.md) ，然后将其在 K8s 中作为容器化应用运行。

```bash
wget -qO- https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/kubernetes_crio/simple_wasi_application.sh | bash
```

应该会看到控制台日志中打印的 WebAssembly 程序的结果。 [这里是一个示例](https://github.com/second-state/wasmedge-containers-examples/runs/4186005677?check_suite_focus=true#step:6:3007).

以下部分是上述 demo 的分步说明。

## 安装 WasmEdge

使用 [simple install script](https://github.com/WasmEdge/WasmEdge/blob/master/docs/install.md) 安装 WasmEdge。

```bash
wget -qO- https://raw.githubusercontent.com/WasmEdge/WasmEdge/master/utils/install.sh | bash -s -- -p /usr/local
```

## 构建和安装 crun

你需要一个支持 WasmEdge 的 `crun` 二进制文件。 目前，最简单的方法是自己从源代码构建它。 首先，让我们确保在你的 Ubuntu 20.04 上安装了 `crun` 依赖项。
对于其他 Linux 发行版，请[见这里](https://github.com/containers/crun#readme).

```bash
sudo apt update
sudo apt install -y make git gcc build-essential pkgconf libtool \
   libsystemd-dev libprotobuf-c-dev libcap-dev libseccomp-dev libyajl-dev \
   go-md2man libtool autoconf python3 automake systemctl
```

接下来，配置、构建和安装带有 WasmEdge 支持的 `crun` 二进制文件。

```bash
git clone https://github.com/containers/crun
cd crun
./autogen.sh
./configure --with-wasmedge
make
sudo make install
```

## 安装 CRI-O

使用以下命令在您的系统上安装 CRI-O。

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

## 配置 CRI-O

CRI-O 默认使用 `runc` runtime，我们需要将其配置为使用 `crun`。
这是通过添加到两个配置文件来完成的。

首先创建一个 `/etc/crio/crio.conf` 文件并添加下面几行作为内容。它告诉 CRI-O 默认使用 `crun` 。

```
[crio.runtime]
default_runtime = "crun"
```

`crun` runtime 因此在 `/etc/crio/crio.conf.d/01-crio-runc.conf` 文件中定义。

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

接下来，重启 CRI-O 让修改过的配置生效.

```bash
systemctl restart crio
```

## 安装和启动 K8s

从一个终端窗口运行如下命令。它为本地开发设置K8s。

```bash
# 安装 go
wget https://golang.org/dl/go1.17.1.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.17.1.linux-amd64.tar.gz
source /home/${USER}/.profile

# Clone k8s
git clone https://github.com/kubernetes/kubernetes.git
cd kubernetes
git checkout v1.22.2
cd ../

# 在 k8s 中使用 hack 脚本安装 etcd
sudo CGROUP_DRIVER=systemd CONTAINER_RUNTIME=remote CONTAINER_RUNTIME_ENDPOINT='unix:///var/run/crio/crio.sock' ./hack/install-etcd.sh
export PATH="/home/${USER}/kubernetes/third_party/etcd:${PATH}"
sudo cp third_party/etcd/etcd* /usr/local/bin/

# 在运行上面的命令后，可以找到如下文件：/usr/local/bin/etcd  /usr/local/bin/etcdctl  /usr/local/bin/etcdutl

# 用 CRI-O 构建和运行 k8s 
sudo apt-get install -y build-essential
sudo CGROUP_DRIVER=systemd CONTAINER_RUNTIME=remote CONTAINER_RUNTIME_ENDPOINT='unix:///var/run/crio/crio.sock' ./hack/local-up-cluster.sh

... ...
本地 Kubernetes 集群正在运行。按 Ctrl-C 将其关闭。
```
  
不要关闭你的终端窗口。Kubernetes 正在运行！

## 运行一个简单的 WebAssembly app

最后我们可以使用 Kubernetes 运行一个简单的 WebAssembly程序。 [一篇单独的文章](../simple_wasi_app.md)解释了如何编译、打包和发布 WebAssembly 程序作为容器镜像到 Docker hub 中。
本章节中，我们将从**另一个终端窗口**开始，并开始使用集群。

```bash
  export KUBERNETES_PROVIDER=local

  cluster/kubectl.sh config set-cluster local --server=https://localhost:6443 --certificate-authority=/var/run/kubernetes/server-ca.crt
  cluster/kubectl.sh config set-credentials myself --client-key=/var/run/kubernetes/client-admin.key --client-certificate=/var/run/kubernetes/client-admin.crt
  cluster/kubectl.sh config set-context local --cluster=local --user=myself
  cluster/kubectl.sh config use-context local
  cluster/kubectl.sh
```

让我们查看状态确保集群正在运行。

```bash
sudo cluster/kubectl.sh cluster-info

# Expected output
Cluster "local" set.
User "myself" set.
Context "local" created.
Switched to context "local".
Kubernetes control plane is running at https://localhost:6443
CoreDNS is running at https://localhost:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

进步一 debug 和检测集群问题，使用 'kubectl cluster-info dump'.
```

我们可以从 Kubernetes 集群中的 Docker Hub 运行基于 WebAssembly 的镜像。

```bash
sudo cluster/kubectl.sh run -it --rm --restart=Never wasi-demo --image=hydai/wasm-wasi-example:with-wasm-annotation /wasi_example_main.wasm 50000000
Random number: 401583443
Random bytes: [192, 226, 162, 92, 129, 17, 186, 164, 239, 84, 98, 255, 209, 79, 51, 227, 103, 83, 253, 31, 78, 239, 33, 218, 68, 208, 91, 56, 37, 200, 32, 12, 106, 101, 241, 78, 161, 16, 240, 158, 42, 24, 29, 121, 78, 19, 157, 185, 32, 162, 95, 214, 175, 46, 170, 100, 212, 33, 27, 190, 139, 121, 121, 222, 230, 125, 251, 21, 210, 246, 215, 127, 176, 224, 38, 184, 201, 74, 76, 133, 233, 129, 48, 239, 106, 164, 190, 29, 118, 71, 79, 203, 92, 71, 68, 96, 33, 240, 228, 62, 45, 196, 149, 21, 23, 143, 169, 163, 136, 206, 214, 244, 26, 194, 25, 101, 8, 236, 247, 5, 164, 117, 40, 220, 52, 217, 92, 179]
Printed from wasi: This is from a main function
This is from a main function
The env vars are as follows.
The args are as follows.
/wasi_example_main.wasm
50000000
File content is This is in a file
pod "wasi-demo-2" deleted
```

完成！

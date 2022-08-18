# 在 CRI-O 中管理 WasmEdge 应用

## 快速开始

可以使用 [install.sh](install.sh) 脚本在 Ubuntu 20.04上安装 CRI-O 和 `crun`。

```bash
wget -qO- https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/crio/install.sh | bash
```

[simple_wasi_application.sh](simple_wasi_application.sh) 脚本显示如何从Docker Hub拉取 [一个 WebAssembly 应用程序](../simple_wasi_app.md) ，然后在 CRI-O 中将其作为容器化应用程序运行。

```bash
wget -qO- https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/crio/simple_wasi_application.sh | bash
```
您应该会在控制台日志中看到来自 WebAssembly 程序的结果。 [这是一个示例](https://github.com/second-state/wasmedge-containers-examples/runs/4186936596?check_suite_focus=true#step:4:40)。

以下是上述 demo 的分步指引。

## 安装 WasmEdge

使用[简单安装脚本](https://github.com/WasmEdge/WasmEdge/blob/master/docs/install.md) 来安装 WasmEdge。

```bash
wget -qO- https://raw.githubusercontent.com/WasmEdge/WasmEdge/master/utils/install.sh | bash -s -- -p /usr/local
```

## 构建和安装 crun

你需要一个支持 WasmEdge 的 `crun` 二进制文件。 目前，最简单的方法是自己从源代码构建它。 首先，让我们确保在您的 Ubuntu 20.04 上安装了 `crun` 依赖项。
对于其他 Linux 发行版，请[在此查看](https://github.com/containers/crun#readme).

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

首先，创建一个 `/etc/crio/crio.conf` 文件并添加以下几行作为其内容。 它默认告诉 CRI-O 使用 `crun`。


```
[crio.runtime]
default_runtime = "crun"
```

 `crun` runtime 从而在 `/etc/crio/crio.conf.d/01-crio-runc.conf` 文件中被定义。

```
[crio.runtime.runtimes.runc]
runtime_path = "/usr/lib/cri-o-runc/sbin/runc"
runtime_type = "oci"
runtime_root = "/run/runc"
# 上面是原本内容

# 在此添加我们的 crunw runtime 
[crio.runtime.runtimes.crun]
runtime_path = "/usr/bin/crun"
runtime_type = "oci"
runtime_root = "/run/crun"
```

接下来，重新启动 CRI-O 来应用配置变化。

```bash
systemctl restart crio
```

## 运行简单的 WebAssembly app

最后，我们可以使用 CRI-O 运行一个简单的 WebAssembly 程序。
[另外的文章](../simple_wasi_app.md) 解释了如何将程序作为容器镜像编译、打包和发布 WebAssembly
将程序到 Docker hub。
在本节中，我们将开始使用 CRI-O 工具从 Docker 中心拉取这个基于 WebAssembly 的容器镜像。

```bash
crictl pull docke.io/hydai/wasm-wasi-example:with-wasm-annotation
```
接下来，我们需要创建两个简单的配置文件，指定CRI-O 应该如何在沙箱中运行这个 WebAssembly 镜像。 我们已经有了这两个文件 [container_wasi.json](container_wasi.json) 和 [sandbox_config.json](sandbox_config.json)。
您可以将它们下载到您的本地目录，如下所示。

```bash
wget https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/crio/sandbox_config.json
wget https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/crio/container_wasi.json
```

现在你可以使用 CRI-O 来创建一个 pod 和一个容器，采用特定的配置。 

```bash
# 创建 POD。 输出将与示例不同。
sudo crictl runp sandbox_config.json
7992e75df00cc1cf4bff8bff660718139e3ad973c7180baceb9c84d074b516a4
# Set a helper variable for later use.
POD_ID=7992e75df00cc1cf4bff8bff660718139e3ad973c7180baceb9c84d074b516a4

# 创建容器实例。 输出将与示例不同。
sudo crictl create $POD_ID container_wasi.json sandbox_config.json
1d056e4a8a168f0c76af122d42c98510670255b16242e81f8e8bce8bd3a4476f
```

启动容器将执行 WebAssembly 程序。 您可以在控制台中看到输出。

```bash
# 列出容器，状态应该为 `Created`
sudo crictl ps -a

CONTAINER           IMAGE                                          CREATED              STATE               NAME                     ATTEMPT             POD ID
1d056e4a8a168       wasmedge/example-wasi:latest                   About a minute ago   Created             podsandbox1-wasm-wasi   0                   7992e75df00cc

# 启动容器
sudo crictl start 1d056e4a8a168f0c76af122d42c98510670255b16242e81f8e8bce8bd3a4476f
1d056e4a8a168f0c76af122d42c98510670255b16242e81f8e8bce8bd3a4476f

# 再次查看容器状态。
# 如果容器未完成其工作，您将看到 Running 状态
# 因为这个示例很小。 此时您可能会看到 Exited。

sudo crictl ps -a
CONTAINER           IMAGE                                          CREATED              STATE               NAME                     ATTEMPT             POD ID
1d056e4a8a168       wasmedge/example-wasi:latest                   About a minute ago   Running             podsandbox1-wasm-wasi   0                   7992e75df00cc

# 当容器完成了以后，状态会显示为 Exited。
sudo crictl ps -a
CONTAINER           IMAGE                                          CREATED              STATE               NAME                     ATTEMPT             POD ID
1d056e4a8a168       wasmedge/example-wasi:latest                   About a minute ago   Exited              podsandbox1-wasm-wasi   0                   7992e75df00cc

# 查看容器的log
sudo crictl logs 1d056e4a8a168f0c76af122d42c98510670255b16242e81f8e8bce8bd3a4476f

Test 1: 打印随机数
Random number: 960251471

Test 2: Print Random Bytes
Random bytes: [50, 222, 62, 128, 120, 26, 64, 42, 210, 137, 176, 90, 60, 24, 183, 56, 150, 35, 209, 211, 141, 146, 2, 61, 215, 167, 194, 1, 15, 44, 156, 27, 179, 23, 241, 138, 71, 32, 173, 159, 180, 21, 198, 197, 247, 80, 35, 75, 245, 31, 6, 246, 23, 54, 9, 192, 3, 103, 72, 186, 39, 182, 248, 80, 146, 70, 244, 28, 166, 197, 17, 42, 109, 245, 83, 35, 106, 130, 233, 143, 90, 78, 155, 29, 230, 34, 58, 49, 234, 230, 145, 119, 83, 44, 111, 57, 164, 82, 120, 183, 194, 201, 133, 106, 3, 73, 164, 155, 224, 218, 73, 31, 54, 28, 124, 2, 38, 253, 114, 222, 217, 202, 59, 138, 155, 71, 178, 113]

Test 3: 调用 echo 函数
Printed from wasi: This is from a main function
This is from a main function

Test 4: 打印环境变量
The env vars are as follows.
PATH: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
TERM: xterm
HOSTNAME: crictl_host
PATH: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
The args are as follows.
/var/lib/containers/storage/overlay/006e7cf16e82dc7052994232c436991f429109edea14a8437e74f601b5ee1e83/merged/wasi_example_main.wasm
50000000

Test 5: 创建文件 `/tmp.txt` 带有内容 `This is in a file`

Test 6: 从前面的文件中读取文件
文件内容是 This is in a file

Test 7: 删除前面的文件
```

完成！

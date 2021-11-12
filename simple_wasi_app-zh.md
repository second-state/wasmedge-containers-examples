# 一个 WASI WebAssembly 应用的容器镜像

在本文中，我将向您展示如何为 WebAssembly 应用程序构建容器镜像。 然后可以通过 Kubernetes 生态系统工具启动和管理它，例如 CRI-O、Docker、crun 和 Kubernetes。

## 先决条件

> 如果只是希望将 wasm 字节码文件作为容器镜像进行测试，则可以跳过构建过程，只需 [在此处下载 wasm 文件] (https://github.com/second-state/wasm-learning/blob/master/cli/wasi/wasi_example_main.wasm).

如果还未安装，请按照以下简单的说明 [安装 Rust](https://www.rust-lang.org/tools/install).

## 下载示例代码

```bash
git clone https://github.com/second-state/wasm-learning
cd wasm-learning/cli/wasi
```

## 构建 WASM 字节码

```bash
rustup target add wasm32-wasi
cargo build --target wasm32-wasi --release
```

wasm 字节码应用程序在 `target/wasm32-wasi/release/wasi_example_main.wasm` 文件中。你现在可以发布并将它用作容器镜像。 

## 对 Wasm 字节码应用可执行权限

```bash
chmod +x target/wasm32-wasi/release/wasi_example_main.wasm
```

## 创建 Dockerfile

在 `target/wasm32-wasi/release/` 文件夹中创建一个名为 `Dockerfile` 的文件，内容如下：

```
FROM scratch
ADD wasi_example_main.wasm /
CMD ["/wasi_example_main.wasm"]
```

## 创建带有注释的容器镜像

> 请注意，添加自定义注解仍然是 buildah 中的一个新功能。

`crun` 容器运行时可以启动上述基于 WebAssembly 的容器镜像。 但是它需要容器镜像上的 `module.wasm.image/variant=compat` 注释来表明它是一个没有 guest 操作系统的 WebAssembly 应用程序。 可以在[官方crun repo]中找到详细信息(https://github.com/containers/crun/blob/main/docs/wasm-wasi-example.md).

在容器镜像中添加 `module.wasm.image/variant=compat` 注释，你需要最新的 [buildah](https://buildah.io/)。目前，Docker 不支持此功能。 请按照[buildah的安装说明](https://github.com/containers/buildah/blob/main/install.md)构建最新的buildah二进制文件。

### 在 Ubuntu 上构建并安装最新的 buildah

在 Ubuntu zesty 和 xenial 上，使用这些命令为 buildah 做准备。

```bash
sudo apt-get -y install software-properties-common
sudo add-apt-repository -y ppa:alexlarsson/flatpak
sudo add-apt-repository -y ppa:gophers/archive
sudo apt-add-repository -y ppa:projectatomic/ppa
sudo apt-get -y -qq update
sudo apt-get -y install bats git libapparmor-dev libdevmapper-dev libglib2.0-dev libgpgme11-dev libseccomp-dev libselinux1-dev skopeo-containers go-md2man
sudo apt-get -y install golang-1.13
```

然后，按照以下步骤在 Ubuntu 上构建和安装 buildah。

```bash
mkdir -p ~/buildah
cd ~/buildah
export GOPATH=`pwd`
git clone https://github.com/containers/buildah ./src/github.com/containers/buildah
cd ./src/github.com/containers/buildah
PATH=/usr/lib/go-1.13/bin:$PATH make
cp bin/buildah /usr/bin/buildah
buildah --help
```

### 使用 buildah 创建和发布容器镜像

在 `target/wasm32-wasi/release/` 文件中，进行如下操作。

```bash
sudo buildah build --annotation "module.wasm.image/variant=compat" -t wasm-wasi-example .
# You may need to use docker login to create the `~/.docker/config.json` for auth.
sudo buildah push --authfile ~/.docker/config.json wasm-wasi-example docker://docker.io/hydai/wasm-wasi-example:with-wasm-annotation
```

完成！

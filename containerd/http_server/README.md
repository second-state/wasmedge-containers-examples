# Manage WasmEdge apps in Containerd

## Quick start

You can use the [install.sh](../install.sh) script to install containerd and `crun` on Ubuntu 20.04.

```bash
wget -qO- https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/containerd/install.sh | bash
```

The [http_server_application.sh](http_server_application.sh) script shows how to pull [a WebAssembly application](../../http_server_wasi_app.md) from Docker Hub, and then run it as a containerized application in containerd.

```bash
wget -qO- https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/containerd/http_server/http_server_application.sh | bash
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
   go-md2man libtool autoconf python3 automake
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

## Install containerd

Use the following commands to install containerd on your system.

```bash
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

## Configure containerd

```
# TODO: add containerd configuration for runc (for demo no extra config needed)
```

## Run a simple WebAssembly app

Finally, we can run a simple WebAssembly program using containerd.
[A seperate article](../../http_server_wasi_app.md) explains how to compile, package, and publish the WebAssembly
program as a container image to Docker hub.
In this section, we will start off pulling this WebAssembly-based container
image from Docker hub using containerd tools.

```bash
sudo ctr i pull docker.io/wasmedge/example-wasi-http:latest
```

We can run the example in just one line with ctr (the containerd cli).
Notice that we are running the container with `--net-host`
so that the HTTP server inside the WasmEdge container is accessible from the outside shell.

```bash
sudo ctr run --rm --net-host --runc-binary crun --runtime io.containerd.runc.v2 --label module.wasm.image/variant=compat-smart docker.io/wasmedge/example-wasi-http http-server-example /http_server.wasm
```

From another terminal, access the HTTP service inside the WasmEdge container on the local machine using the `curl` command.

```bash
curl -d "name=WasmEdge" -X POST http://127.0.0.1:1234
echo: name=WasmEdge
```

In addition, you can check the status and get detailed information about the `http-server-example` container.

```bash
sudo ctr container info http-server-example
```

That's it!

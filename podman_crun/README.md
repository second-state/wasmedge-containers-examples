# Manage WasmEdge apps in Containerd

## Quick start

You can use the [install.sh](install.sh) script to install podman, wasmedge and `crun` on Ubuntu 20.04.

```bash
wget -qO- https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/podman_crun/install.sh | bash
```

The [simple_wasi_application.sh](simple_wasi_application.sh) script shows how to pull [a WebAssembly application](../simple_wasi_app.md) from Docker Hub, and then run it as a containerized application using podman.

```bash
wget -qO- https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/podman_crun/simple_wasi_application.sh | bash
```

You should see results from the WebAssembly program printed in the console log. [Here is an example](https://github.com/second-state/wasmedge-containers-examples/runs/4321868699?check_suite_focus=true#step:4:63).

The sections below are step-by-step instructions for the above demo.
## Install podman
```
sudo apt-get -y update
sudo apt-get -y install podman 
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
[A seperate article](../simple_wasi_app.md) explains how to compile, package, and publish the WebAssembly
program as a container image to Docker hub.
In this section, we will start off pulling this WebAssembly-based container
image from Docker hub using podman.

```bash
sudo podman pull docker.io/hydai/wasm-wasi-example:with-wasm-annotation
```

We can run the example in just one line with podman

```bash
sudo podman run docker.io/hydai/wasm-wasi-example:with-wasm-annotation  /wasi_example_main.wasm 50000000
Random number: -214629337
Random bytes: [130, 112, 216, 9, 42, 219, 211, 166, 21, 133, 37, 60, 37, 186, 225, 57, 222, 20, 88, 33, 226, 219, 163, 139, 131, 130, 194, 208, 55, 253, 179, 65, 199, 80, 60, 62, 37, 226, 170, 115, 251, 101, 111, 222, 160, 133, 77, 128, 169, 197, 21, 68, 213, 41, 39, 179, 153, 149, 166, 173, 67, 26, 225, 156, 111, 178, 95, 251, 94, 228, 45, 143, 253, 39, 82, 225, 38, 118, 241, 85, 119, 118, 139, 103, 203, 65, 99, 160, 23, 194, 111, 204, 46, 74, 82, 35, 202, 170, 119, 215, 31, 61, 235, 237, 35, 2, 60, 139, 12, 12, 130, 16, 64, 226, 39, 169, 219, 121, 99, 201, 143, 144, 141, 253, 101, 140, 186, 57]
Printed from wasi: This is from a main function
This is from a main function
The env vars are as follows.
The args are as follows.
/wasi_example_main.wasm
50000000
File content is This is in a file
```

Check the container status again.
```shell
sudo podman ps -a
CONTAINER ID  IMAGE                                                   COMMAND               CREATED        STATUS                    PORTS       NAMES
c41ba854164a  docker.io/hydai/wasm-wasi-example:with-wasm-annotation  /wasi_example_mai...  7 seconds ago  Exited (0) 8 seconds ago              jolly_kowalevski
```

Check the container's logs
```shell
sudo podman logs c41ba854164a
Random number: -534587364
Random bytes: [131, 209, 233, 6, 214, 88, 34, 220, 29, 238, 69, 112, 119, 17, 95, 103, 71, 79, 191, 26, 59, 59, 234, 56, 134, 100, 221, 145, 54, 52, 205, 70, 116, 143, 30, 69, 154, 67, 13, 31, 14, 85, 7, 12, 230, 91, 215, 127, 35, 16, 228, 89, 250, 74, 157, 237, 225, 177, 195, 38, 115, 13, 16, 7, 226, 36, 152, 140, 240, 224, 215, 66, 84, 244, 146, 24, 90, 42, 78, 151, 147, 173, 72, 11, 245, 185, 208, 50, 223, 84, 221, 30, 154, 56, 222, 85, 172, 127, 121, 111, 228, 131, 23, 106, 226, 248, 208, 27, 88, 83, 219, 218, 72, 180, 42, 224, 62, 154, 153, 123, 47, 48, 197, 159, 9, 4, 106, 232]
Printed from wasi: This is from a main function
This is from a main function
The env vars are as follows.
The args are as follows.
/wasi_example_main.wasm
50000000
File content is This is in a file
```

Clean up
```shell
sudo podman rm c41ba854164a
c41ba854164a7fbd7bc524733f12012f413969d4a24dd4897804e22858135431
```

That's it!

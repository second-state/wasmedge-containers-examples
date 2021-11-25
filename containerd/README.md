# Manage WasmEdge apps in Containerd

## Quick start

You can use the [install.sh](install.sh) script to install containerd and `crun` on Ubuntu 20.04.

```bash
wget -qO- https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/containerd/install.sh | bash
```

The [simple_wasi_application.sh](simple_wasi_application.sh) script shows how to pull [a WebAssembly application](../simple_wasi_app.md) from Docker Hub, and then run it as a containerized application in containerd.

```bash
wget -qO- https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/containerd/simple_wasi_application.sh | bash
```

You should see results from the WebAssembly program printed in the console log. [Here is an example](https://github.com/second-state/wasmedge-containers-examples/runs/4321868699?check_suite_focus=true#step:4:63).

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
[A seperate article](../simple_wasi_app.md) explains how to compile, package, and publish the WebAssembly
program as a container image to Docker hub.
In this section, we will start off pulling this WebAssembly-based container
image from Docker hub using containerd tools.

```bash
sudo ctr i pull docker.io/hydai/wasm-wasi-example:with-wasm-annotation
```

We can run the example in just one line with ctr (the containerd cli) 

```bash
sudo ctr run --rm --runc-binary crun --runtime io.containerd.runc.v2 --label module.wasm.image/variant=compat docker.io/hydai/wasm-wasi-example:with-wasm-annotation wasm-example /wasi_example_main.wasm 50000000
```

## Bonus: nerdctl

[nerdctl](https://github.com/containerd/nerdctl) is a way more convenient way to manage your containers and since it has the same commands as the docker cli you may are already used to it.

```bash
# Install nerdctl
export NERD_VERSION="0.14.0"
wget -O- https://github.com/containerd/nerdctl/releases/download/v$NERD_VERSION/nerdctl-$NERD_VERSION-linux-amd64.tar.gz |tar xzf -

# Create the POD. Output will be different from example.
sudo ./nerdctl run -d --runtime crun --label module.wasm.image/variant=compat --name wasm-example docker.io/hydai/wasm-wasi-example:with-wasm-annotation
WARN[0000] kernel support for cgroup blkio weight missing, weight discarded 
495ac5a521052bd42dca109f549140d573ad9d114ce3e1d15896156430b95c8f

# Check the container status again.
# If the container is not finishing its job, you will see the Running state
# Because this example is very tiny. You may see Exited at this moment.
sudo ./nerdctl ps -a
CONTAINER ID    IMAGE                                                     COMMAND                   CREATED          STATUS                      PORTS    NAMES
495ac5a52105    docker.io/hydai/wasm-wasi-example:with-wasm-annotation    "/wasi_example_main.…"    8 seconds ago    Exited (0) 8 seconds ago             wasm-example    

# Check the container's logs
sudo ./nerdctl logs wasm-example
Random number: -1759356951
Random bytes: [144, 193, 111, 123, 191, 41, 190, 28, 106, 85, 144, 176, 206, 147, 231, 112, 197, 172, 128, 181, 175, 44, 229, 61, 142, 104, 50, 239, 52, 185, 180, 171, 178, 160, 179, 9, 43, 240, 129, 131, 10, 80, 101, 236, 20, 96, 55, 137, 224, 222, 254, 73, 160, 102, 189, 111, 58, 107, 144, 205, 119, 242, 196, 74, 230, 101, 81, 235, 149, 48, 93, 105, 73, 239, 120, 221, 74, 135, 103, 64, 248, 169, 98, 105, 5, 124, 91, 130, 155, 64, 234, 173, 209, 115, 70, 77, 149, 176, 242, 77, 149, 87, 114, 131, 185, 1, 21, 236, 107, 71, 98, 92, 234, 19, 27, 88, 246, 58, 94, 183, 131, 191, 112, 29, 61, 140, 48, 95]
Printed from wasi: This is from a main function
This is from a main function
The env vars are as follows.
The args are as follows.
/wasi_example_main.wasm
File content is This is in a file

# Clean up
sudo ./nerdctl rm wasm-example
wasm-example
```

That's it!

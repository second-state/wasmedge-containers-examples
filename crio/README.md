# Manage WasmEdge apps in CRI-O

## Quick start

You can use the [install.sh](install.sh) script to install CRI-O and `crun` on Ubuntu 20.04.

```bash
wget -qO- https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/crio/install.sh | bash
```

The [simple_wasi_application.sh](simple_wasi_application.sh) script shows how to pull [a WebAssembly application](../simple_wasi_app.md) from Docker Hub, and then run it as a containerized application in CRI-O.

```bash
wget -qO- https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/crio/simple_wasi_application.sh | bash
```

You should see results from the WebAssembly program printed in the console log. [Here is an example](https://github.com/second-state/wasmedge-containers-examples/runs/4186936596?check_suite_focus=true#step:4:40).

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

## Run a simple WebAssembly app

Finally, we can run a simple WebAssembly program using CRI-O.
[A seperate article](../simple_wasi_app.md) explains how to compile, package, and publish the WebAssembly
program as a container image to Docker hub.
In this section, we will start off pulling this WebAssembly-based container
image from Docker hub using CRI-O tools.

```bash
crictl pull docker.io/wasmedge/example-wasi:latest
```

Next, we need to create two simple configuration files that specifies how
CRI-O should run this WebAssembly image in a sandbox. We already have those
two files [container_wasi.json](container_wasi.json) and [sandbox_config.json](sandbox_config.json).
You can just download them to your local directory as follows.

```bash
wget https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/crio/sandbox_config.json
wget https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/crio/container_wasi.json
```

Now you can use CRI-O to create a pod and a container using the specified configurations.

```bash
# Create the POD. Output will be different from example.
sudo crictl runp sandbox_config.json
7992e75df00cc1cf4bff8bff660718139e3ad973c7180baceb9c84d074b516a4
# Set a helper variable for later use.
POD_ID=7992e75df00cc1cf4bff8bff660718139e3ad973c7180baceb9c84d074b516a4

# Create the container instance. Output will be different from example.
sudo crictl create $POD_ID container_wasi.json sandbox_config.json
1d056e4a8a168f0c76af122d42c98510670255b16242e81f8e8bce8bd3a4476f
```

Starting the container would execute the WebAssembly program. You can see the output in the console.

```bash
# List the container, the state should be `Created`
sudo crictl ps -a

CONTAINER           IMAGE                                          CREATED              STATE               NAME                     ATTEMPT             POD ID
1d056e4a8a168       wasmedge/example-wasi:latest                   About a minute ago   Created             podsandbox1-wasm-wasi   0                   7992e75df00cc

# Start the container
sudo crictl start 1d056e4a8a168f0c76af122d42c98510670255b16242e81f8e8bce8bd3a4476f
1d056e4a8a168f0c76af122d42c98510670255b16242e81f8e8bce8bd3a4476f

# Check the container status again.
# If the container is not finishing its job, you will see the Running state
# Because this example is very tiny. You may see Exited at this moment.
sudo crictl ps -a
CONTAINER           IMAGE                                          CREATED              STATE               NAME                     ATTEMPT             POD ID
1d056e4a8a168       wasmedge/example-wasi:latest                   About a minute ago   Running             podsandbox1-wasm-wasi   0                   7992e75df00cc

# When the container is finished. You can see the state becomes Exited.
sudo crictl ps -a
CONTAINER           IMAGE                                          CREATED              STATE               NAME                     ATTEMPT             POD ID
1d056e4a8a168       wasmedge/example-wasi:latest                   About a minute ago   Exited              podsandbox1-wasm-wasi   0                   7992e75df00cc

# Check the container's logs
sudo crictl logs 1d056e4a8a168f0c76af122d42c98510670255b16242e81f8e8bce8bd3a4476f

Test 1: Print Random Number
Random number: 960251471

Test 2: Print Random Bytes
Random bytes: [50, 222, 62, 128, 120, 26, 64, 42, 210, 137, 176, 90, 60, 24, 183, 56, 150, 35, 209, 211, 141, 146, 2, 61, 215, 167, 194, 1, 15, 44, 156, 27, 179, 23, 241, 138, 71, 32, 173, 159, 180, 21, 198, 197, 247, 80, 35, 75, 245, 31, 6, 246, 23, 54, 9, 192, 3, 103, 72, 186, 39, 182, 248, 80, 146, 70, 244, 28, 166, 197, 17, 42, 109, 245, 83, 35, 106, 130, 233, 143, 90, 78, 155, 29, 230, 34, 58, 49, 234, 230, 145, 119, 83, 44, 111, 57, 164, 82, 120, 183, 194, 201, 133, 106, 3, 73, 164, 155, 224, 218, 73, 31, 54, 28, 124, 2, 38, 253, 114, 222, 217, 202, 59, 138, 155, 71, 178, 113]

Test 3: Call an echo function
Printed from wasi: This is from a main function
This is from a main function

Test 4: Print Environment Variables
The env vars are as follows.
PATH: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
TERM: xterm
HOSTNAME: crictl_host
PATH: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
The args are as follows.
/var/lib/containers/storage/overlay/006e7cf16e82dc7052994232c436991f429109edea14a8437e74f601b5ee1e83/merged/wasi_example_main.wasm
50000000

Test 5: Create a file `/tmp.txt` with content `This is in a file`

Test 6: Read the content from the previous file
File content is This is in a file

Test 7: Delete the previous file
```

That's it!

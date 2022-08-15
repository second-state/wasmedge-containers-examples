# Container image for a WASI WebAssembly app

In this article, I will show you two methods(actually, two tools to build images: buildah and docker buildx) how to build a container image for a WebAssembly application. It can then be started and managed by Kubernetes ecosystem tools, such as CRI-O, Docker, crun, and Kubernetes.

## Buildah
### Prerequisites

> If you simply want a wasm bytecode file to test as a container image, you can skip the building process and just [download the wasm file here](https://github.com/second-state/wasm-learning/blob/master/cli/wasi/wasi_example_main.wasm).

If you have not done so already, follow these simple instructions to [install Rust](https://www.rust-lang.org/tools/install).

### Download example code

```bash
git clone https://github.com/second-state/wasm-learning
cd wasm-learning/cli/wasi
```

### Build the WASM bytecode

```bash
rustup target add wasm32-wasi
cargo build --target wasm32-wasi --release
```

The wasm bytecode application is in the `target/wasm32-wasi/release/wasi_example_main.wasm` file. You can now publish and use it as a container image.

### Apply executable permission on the Wasm bytecode

```bash
chmod +x target/wasm32-wasi/release/wasi_example_main.wasm
```

### Create Dockerfile

Create a file called `Dockerfile` in the `target/wasm32-wasi/release/` folder with the following content:

```
FROM scratch
ADD wasi_example_main.wasm /
CMD ["/wasi_example_main.wasm"]
```

### Create container image with annotations

> Please note that adding self-defined annotation is still a new feature in buildah.

The `crun` container runtime can start the above WebAssembly-based container image. But it requires the `module.wasm.image/variant=compat` annotation on the container image to indicate that it is a WebAssembly application without a guest OS. You can find the details in [Official crun repo](https://github.com/containers/crun/blob/main/docs/wasm-wasi-example.md).

To add `module.wasm.image/variant=compat` annotation in the container image, you will need the latest [buildah](https://buildah.io/). Currently, Docker does not support this feature. Please follow [the install instructions of buildah](https://github.com/containers/buildah/blob/main/install.md) to build the latest buildah binary.

#### Build and install the latest buildah on Ubuntu

On Ubuntu zesty and xenial, use these commands to prepare for buildah.

```bash
sudo apt-get -y install software-properties-common

export OS="xUbuntu_20.04"
sudo bash -c "echo \"deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /\" > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list"
sudo bash -c "curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | apt-key add -"

sudo add-apt-repository -y ppa:alexlarsson/flatpak
sudo apt-get -y -qq update
sudo apt-get -y install bats git libapparmor-dev libdevmapper-dev libglib2.0-dev libgpgme-dev libseccomp-dev libselinux1-dev skopeo-containers go-md2man containers-common
sudo apt-get -y install golang-1.16 make
```

Then, follow these steps to build and install buildah on Ubuntu.

```bash
mkdir -p ~/buildah
cd ~/buildah
export GOPATH=`pwd`
git clone https://github.com/containers/buildah ./src/github.com/containers/buildah
cd ./src/github.com/containers/buildah
PATH=/usr/lib/go-1.16/bin:$PATH make
sudo cp bin/buildah /usr/bin/buildah
buildah --help
```

#### Create and publish a container image with buildah

In the `target/wasm32-wasi/release/` folder, do the following.

```bash
sudo buildah build --annotation "module.wasm.image/variant=compat" -t wasm-wasi-example .
# make sure docker is install and running
# systemctl status docker
# to make sure regular user can use docker
# sudo usermod -aG docker $USER
# newgrp docker
# You may need to use docker login to create the `~/.docker/config.json` for auth.
sudo buildah push --authfile ~/.docker/config.json wasm-wasi-example docker://docker.io/hydai/wasm-wasi-example:with-wasm-annotation
```

## docker buildx

When using Docker tool to build the image, the steps before building the image are actually the same as buildah tool.
You can follow these steps above to prepare the WASM bytecode and create dockerfile.


### Create container image with annotations
In this [issue](https://github.com/docker/buildx/issues/1171), adding the annotation flag to docker buildx is mentioned.
Because,the OCI image spec allows specifying annotations on index entries.
so,this [PR](https://github.com/moby/buildkit/pull/2879) introduces support for creating and attaching annotations to the exporter.

#### build and install docker and buildkit on Ubuntu
Automatic installation using the official script:
```shell
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
```
Then, build and install buildkit from source as these following steps,
at the same time, buildkitd and buildctl installed to /usr/local/bin:
```shell
git clone git@github.com:moby/buildkit.git
cd buildkit
make && sudo make install
buildctl --version
buildkit --version
```

#### Create container image with docker buildx
In the `target/wasm32-wasi/release/` folder, do the following.
```shell
sudo docker buildx build  --output type=image,name=example/foo,push=true,annotation.module.wasm.image/variant=compat  -f Dockerfile -t myimage:latest .
# make sure docker is install and running
# systemctl status docker
# to make sure regular user can use docker
# sudo usermod -aG docker $USER
# newgrp docker
# You may need to use docker login to create the `~/.docker/config.json` f
sudo docker push zjujinchen/myimage:latest
```




That's it!

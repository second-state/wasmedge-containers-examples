# WASI standalone app

In this example, we demonstrate how to build a standalone WASM application from the rust application.

## Prerequisites

> If you simply want a wasm bytecode file to test as a container image, you can skip the building process and just [download the wasm file here](https://github.com/second-state/wasm-learning/blob/master/ssvm/wasi/wasi_example_main.wasm).

If you have not done so already, follow these simple instructions to [install Rust and rustwasmc](https://www.secondstate.io/articles/rustwasmc/) toolchain.

## Download example code

```bash
git clone git@github.com:second-state/wasm-learning.git
cd cli/wasi
```

## Build the WASM bytecode

```bash
rustwasmc build
```

The wasm bytecode application is in `pkg/wasi_example_main.wasm` file. You can now publish and use it as a container image.

## Apply executable permission on the Wasm bytecode

```bash
chmod +x pkg/wasi_example_main.wasm
```

## Create Dockerfile

Create a file called `Dockerfile` in the `pkg` folder with the following content:

```
FROM scratch
ADD wasi_example_main.wasm /
CMD ["/wasi_example_main.wasm"]
```

## Create container image without annotations

This example uses [docker](https://github.com/docker/cli) to build image. You can use any other tools to create container image.

Here is an example of creating container image and publishing the wasm bytecode file to the public Docker hub.

```bash
sudo docker build -f Dockerfile -t hydai/wasm-wasi-example:latest .
sudo docker push hydai/wasm-wasi-example:latest
```

## Create container image with annotations

**Please notice that adding self-defined annotations is a pretty new feature in buildah**

Creating a container image with `module.wasm.image/variant=compat` annotation will make your wasm container image run by crun with WasmEdge support.

You can find the details in [Official crun repo](https://github.com/containers/crun/blob/main/docs/wasm-wasi-example.md).

To add `module.wasm.image/variant=compat` annotation in the container image, you will need the latest buildah. Currently, docker is not support this feature.

Please follow [the install instructions of buildah](https://github.com/containers/buildah/blob/main/install.md) to build the latest buildah binary.

### Build latest buildah on Ubuntu

In Ubuntu zesty and xenial, you can use these commands:

```bash
  sudo apt-get -y install software-properties-common
  sudo add-apt-repository -y ppa:alexlarsson/flatpak
  sudo add-apt-repository -y ppa:gophers/archive
  sudo apt-add-repository -y ppa:projectatomic/ppa
  sudo apt-get -y -qq update
  sudo apt-get -y install bats git libapparmor-dev libdevmapper-dev libglib2.0-dev libgpgme11-dev libseccomp-dev libselinux1-dev skopeo-containers go-md2man
  sudo apt-get -y install golang-1.13
```

Then to install Buildah on Ubuntu follow the steps in this example:

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

### Create container image with buildah

In the `pkg` folder:

```bash
sudo buildah build --annotation "module.wasm.image/variant=compat" -t wasm-wasi-example .
# You may need to use docker login to create the `~/.docker/config.json` for auth.
sudo buildah push --authfile ~/.docker/config.json wasm-wasi-example docker://docker.io/hydai/wasm-wasi-example:with-wasm-annotation
```

# Container image for a WASI WebAssembly app

In this article, I will show you how to build a container image for a WebAssembly application. It can then be started and managed by Kubernetes ecosystem tools, such as CRI-O, Docker, crun, and Kubernetes.

## Prerequisites

> If you simply want a wasm bytecode file to test as a container image, you can skip the building process and just [download the wasm file here](https://github.com/second-state/wasm-learning/blob/master/cli/wasi/wasi_example_main.wasm).

If you have not done so already, follow these simple instructions to [install Rust](https://www.rust-lang.org/tools/install).

## Download example code

```bash
git clone https://github.com/second-state/wasm-learning
cd wasm-learning/cli/wasi
```

## Build the WASM bytecode

```bash
rustup target add wasm32-wasi
cargo build --target wasm32-wasi --release
```

The wasm bytecode application is in the `target/wasm32-wasi/release/wasi_example_main.wasm` file. You can now publish and use it as a container image.

## Apply executable permission on the Wasm bytecode

```bash
chmod +x target/wasm32-wasi/release/wasi_example_main.wasm
```

## Create Dockerfile

Create a file called `Dockerfile` in the `target/wasm32-wasi/release/` folder with the following content:

```
FROM scratch
ADD wasi_example_main.wasm /
CMD ["/wasi_example_main.wasm"]
```

## Create container image

### Using Docker

#### Install Docker buildx

Please follow the [official docker buildx installation guide](https://docs.docker.com/build/architecture/#install-buildx).

#### Create container image with docker buildx

```bash
# Build image
sudo docker buildx build --platform wasi/wasm -t example-wasi-http .
# Push to docker hub
sudo docker push example-wasi-http
```

### Using Buildah

#### Install Buildah

> Please note that adding self-defined annotation is still a new feature in buildah.

The `crun` container runtime can start the above WebAssembly-based container image. But it requires the `module.wasm.image/variant=compat-smart` annotation on the container image to indicate that it is a WebAssembly application without a guest OS. You can find the details in [Official crun repo](https://github.com/containers/crun/blob/main/docs/wasm-wasi-example.md).

To add `module.wasm.image/variant=compat-smart` annotation in the container image, you will need the latest [buildah](https://buildah.io/). Currently, Docker does not support this feature. Please follow [the install instructions of buildah](https://github.com/containers/buildah/blob/main/install.md) to build the latest buildah binary.

#### Create and publish a container image with buildah

In the `target/wasm32-wasi/release/` folder, do the following.

```bash
sudo buildah build --annotation "module.wasm.image/variant=compat-smart" -t wasm-wasi-example .
#
# make sure docker is install and running
# systemctl status docker
# to make sure regular user can use docker
# sudo usermod -aG docker $USER#
# newgrp docker

# You may need to use docker login to create the `~/.docker/config.json` for auth.
#
# docker login

sudo buildah push --authfile ~/.docker/config.json wasm-wasi-example docker://docker.io/wasmedge/example-wasi-http:latest
```

That's it!

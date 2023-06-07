# Container image for a WebAssembly HTTP Service

Let's build a container image for a WebAssembly HTTP Service, with the WASM module
in the latest crun build. Kubernetes could manage the wasm application lifecycle
with CRI-O, Docker and Containerd.

## Prerequisites

This is a Rust example, which require you to install [Rust](https://www.rust-lang.org/tools/install)
and [WasmEdge](https://github.com/WasmEdge/WasmEdge/blob/master/docs/install.md)
before you can Compile and Run the http service.

## Download example code

```bash

mkdir http_server
cd http_server
wget -q https://raw.githubusercontent.com/second-state/wasmedge_wasi_socket/main/examples/http_server/Cargo.toml
mkdir src
cd src
wget -q https://raw.githubusercontent.com/second-state/wasmedge_wasi_socket/main/examples/http_server/src/main.rs
cd ../

```

## Build the WASM bytecode

```bash
rustup target add wasm32-wasi
cargo build --target wasm32-wasi --release
```

The wasm bytecode application is now should be located in the `./target/wasm32-wasi/release/http_server.wasm`
You can now test run it with wasmedge and then publish it as a container image.

## Apply executable permission on the Wasm bytecode

```bash
chmod +x ./target/wasm32-wasi/release/http_server.wasm
```

## Running the http_server application bytecode with wasmedge

When you run the bytecode with wasmedge and see the result as the following, you
are ready to package the bytecode into the container.

```bash
wasmedge ./target/wasm32-wasi/release/http_server.wasm
new connection at 1234

```

## Create Dockerfile
Create a file called `Dockerfile` in the `target/wasm32-wasi/release/` folder with the following content:

```
FROM scratch
ADD http_server.wasm /
CMD ["/http_server.wasm"]
```

## Create container image

After [podman no longer propogates annotations when running the images](https://github.com/WasmEdge/WasmEdge/issues/2567), there is no reason to create images with annotations anymore, using `--platform wasi/wasm` instead.

### Create and publish a container image with buildah

In the `target/wasm32-wasi/release/` folder, do the following.

```bash
sudo buildah build --platform wasi/wasm -t http_server .
#
# make sure docker is install and running
# systemctl status docker
# to make sure regular user can use docker
# sudo usermod -aG docker $USER#
# newgrp docker

# You may need to use docker login to create the `~/.docker/config.json` for auth.
#
# docker login

sudo buildah push --authfile ~/.docker/config.json http_server docker://docker.io/wasmedge/example-wasi-http:latest
```

That's it!

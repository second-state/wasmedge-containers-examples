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
ADD wasi_example_main.wasm .
CMD ["wasi_example_main.wasm"]
```

## Create container image

This example uses [docker](https://github.com/docker/cli) to build image. You can use any other tools to create container image.

Here is an example of creating container image and publishing the wasm bytecode file to the public Docker hub.

```bash
sudo docker build -f Dockerfile -t hydai/wasm-wasi-example:latest .
sudo docker push hydai/wasm-wasi-example:latest
```

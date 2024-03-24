#!/bin/bash
sudo podman pull docker.io/hydai/wasm-wasi-example:with-wasm-annotation
echo -e "Creating POD ..."
sudo podman run --rm  docker.io/hydai/wasm-wasi-example:with-wasm-annotation  /wasi_example_main.wasm 50000000
echo -e "\n\nFinished\n\n"
echo -e "Done!"

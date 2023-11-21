#!/bin/bash
export WASM_IMAGE=docker.io/wasmedge/example-wasi
export WASM_IMAGE_TAG=latest
export WASM_VARIANT=compat-smart

sudo ctr i pull $WASM_IMAGE:$WASM_IMAGE_TAG
echo -e "Creating POD ..."
sudo ctr run --rm --runc-binary crun \
	--runtime io.containerd.runc.v2 \
	--label module.wasm.image/variant=$WASM_VARIANT \
	$WASM_IMAGE:$WASM_IMAGE_TAG wasm-demo /wasi_example_main.wasm 50000000
echo -e "\n\nFinished\n\n"
echo -e "Done!"

#!/bin/bash
export WASM_IMAGE=docker.io/wasmedge/example-wasi
export WASM_IMAGE_TAG=latest

for opt in "$@"; do
  case $opt in
    --tag=*)
      export WASM_IMAGE_TAG="${opt#*=}"
      shift
      ;;
    *)
      ;;
  esac
done

sudo ctr i pull $WASM_IMAGE:$WASM_IMAGE_TAG
echo -e "Creating POD ..."
sudo ctr run --rm --runc-binary crun \
	--runtime io.containerd.runc.v2 \
	$WASM_IMAGE:$WASM_IMAGE_TAG wasm-demo /wasi_example_main.wasm 50000000
echo -e "\n\nFinished\n\n"
echo -e "Done!"

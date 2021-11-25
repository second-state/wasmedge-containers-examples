#!/bin/bash
sudo ctr i pull docker.io/hydai/wasm-wasi-example:with-wasm-annotation
echo -e "Creating POD ..."
sudo ctr run --rm --runc-binary crun --runtime io.containerd.runc.v2 --label module.wasm.image/variant=compat docker.io/hydai/wasm-wasi-example:with-wasm-annotation wasm-demo /wasi_example_main.wasm 50000000
echo -e "\n\nFinished\n\n"
echo -e "Done!"

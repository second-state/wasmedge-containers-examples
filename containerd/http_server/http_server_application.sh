#!/bin/bash
sudo ctr i pull docker.io/avengermojo/http_server:with-wasm-annotation
echo -e "Creating POD ..."
sudo ctr run --rm --runc-binary crun --runtime io.containerd.runc.v2 --label module.wasm.image/variant=compat docker.io/avengermojo/http_server:with-wasm-annotation http-server-example /http_server.wasm
echo -e "\n\nGetting containers\n\n"
sudo ctr container ls
sudo ctr task ls
echo -e "Sleeping for 10 seconds"
sleep 10
echo -e "Awake again"
echo -e "\n\nGetting containers\n\n"
sudo ctr container ls
sudo ctr task ls
echo -e "\n\nFinished\n\n"
echo -e "Done!"

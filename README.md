# Running lightweight WasmEdge apps side by side with Docker-like containers

The [crun project](https://github.com/containers/crun) now [supports WasmEdge](https://github.com/containers/crun/pull/774/commits/825108e0be3e8de55040f3690c4c2bc2ae7add0f) as a "container" runtime! 
Since `crun` is widely supported across the Kubernetes ecosystem, [WasmEdge](https://github.com/WasmEdge/WasmEdge) applications can now run
everywhere Kubernetes runs!

This repository contains scripts, tutorials, and GitHub Actions to demostrate
how WasmEdge applications work side by side with Docker-like containers.

## Example: A simple WebAssembly app

* CRIO [Quick start](crio/README.md) | [Github Actions](.github/workflows/crio.yml) | [Successful run](https://github.com/second-state/wasmedge-containers-examples/runs/4317457300?check_suite_focus=true#step:4:37) | [Video demo](https://youtu.be/BlLCcAH6Hqo)

* Containerd [Quick start](containerd/README.md) | [Github Actions](.github/workflows/containerd.yml) | [Successful run](https://github.com/second-state/wasmedge-containers-examples/runs/4321868699?check_suite_focus=true#step:4:63) 

* Kubernetes + CRIO [Quick start](kubernetes/README.md) | [Github Actions](.github/workflows/kubernetes.yml) | [Successful run](https://github.com/second-state/wasmedge-containers-examples/runs/4317457304?check_suite_focus=true#step:6:2999)

## Example: A HTTP microservice written in Rust and compiled into WebAssembly

* CRI-O [Quick start](crio/http_server/README.md) | [Github Actions](.github/workflows/crio-server.yml) | [Successful run](https://github.com/second-state/wasmedge-containers-examples/runs/4317457313?check_suite_focus=true#step:4:54)
* Containerd [Quick start](containerd/http_server/README.md) | [Github Actions](.github/workflows/containerd-server.yml) | [Successful run](https://github.com/second-state/wasmedge-containers-examples/runs/4328916842?check_suite_focus=true#step:4:86)

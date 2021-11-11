# Running lightweight WasmEdge apps side by side with Docker-like containers

The [crun project](https://github.com/containers/crun) now [supports WasmEdge](https://github.com/containers/crun/pull/774/commits/825108e0be3e8de55040f3690c4c2bc2ae7add0f) as a "container" runtime! 
Since `crun` is widely supported across the Kubernetes ecosystem, [WasmEdge](https://github.com/WasmEdge/WasmEdge) applications can now run
everywhere Kubernetes runs!

This repository contains scripts, tutorials, and GitHub Actions to demostrate
how WasmEdge applications work side by side with Docker-like containers.

* CRIO [How to](crio/README.md) | [Github Actions](.github/workflows/crio.yml) | [Successful run](https://github.com/second-state/wasmedge-containers-examples/runs/4172499552?check_suite_focus=true) | [Video demo](https://youtu.be/BlLCcAH6Hqo)

* Kubernetes [How to](kubernetes/README.md) | [Github Actions](.github/workflows/kubernetes.yml) | [Successful run](https://github.com/second-state/wasmedge-containers-examples/runs/4172499556?check_suite_focus=true)

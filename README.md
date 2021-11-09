# Running lightweight WasmEdge apps side by side with Docker-like containers

The [crun project](https://github.com/containers/crun) now [supports WasmEdge](https://github.com/containers/crun/pull/774) as a "container" runtime! 
Since `crun` is a [high-performance drop-in replacement](https://www.redhat.com/sysadmin/introduction-crun) for `runc` in almost 
all container and Kubernetes systems, [WasmEdge](https://github.com/WasmEdge/WasmEdge) applications can now run
everywhere Kubernetes runs!

This repository contains scripts, tutorials, and GitHub Actions to demostrate
how WasmEdge applications work side by side with Docker-like containers.

CRIO [How to](crio/README.md) | [Github Actions](.github/workflows/crio.yml) | [Successful run]()

Kubernetes [How to](kubernetes/README.md) | [Github Actions](.github/workflows/kubernetes.yml) | [Successful run]()


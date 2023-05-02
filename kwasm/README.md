# Run a WasmEdge demo app with kwasm-operator

This demo will show how to run a WasmEdge pod with kwasm-operater.

## Create a cluster

Here we use `kind` to create a fresh cluster:

```
kind create cluster
```

## Setup the kwasm operater

- [Install helm](https://helm.sh/docs/intro/install/)
- Setup the kwasm operator
	- Install the kwasm helm repository
	- Install kwasm operator
	- provision nodes

```
helm repo add kwasm http://kwasm.sh/kwasm-operator/
helm install -n kwasm --create-namespace kwasm-operator kwasm/kwasm-operator
kubectl annotate node --all kwasm.sh/kwasm-node=true
```

## Prepare kubernetes configuration files

We will use the [wasmedge/example-wasi](https://hub.docker.com/r/wasmedge/example-wasi) image here.

```yaml
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: crun
handler: crun
---
apiVersion: batch/v1
kind: Job
metadata:
  creationTimestamp: null
  name: wasm-demo
spec:
  template:
    metadata:
      annotations:
        module.wasm.image/variant: compat-smart
      creationTimestamp: null
    spec:
      containers:
      - image: wasmedge/example-wasi:latest
        name: wasm-demo
        resources: {}
        command: ["/wasi_example_main.wasm", "50000000"]
      restartPolicy: Never
      runtimeClassName: crun
  backoffLimit: 1
```

## Apply configuration to start job

Start deployment and service:

```
kubectl apply -f kwasm/simple_wasi_application.yaml

runtimeclass.node.k8s.io/crun created
job.batch/wasm-demo created
```

Check job results:

```
kubectl logs job/wasm-demo

Random number: 1991955132
Random bytes: [85, 233, 5, 237, 63, 35, 194, 202, 225, 32, 136, 112, 40, 181, 98, 33, 152, 226, 177, 57, 53, 31, 211, 1, 18, 195, 142, 99, 165, 149, 105, 201, 200, 83, 84, 168, 255, 228, 68, 33, 248, 241, 118, 41, 249, 164, 131, 239, 57, 90, 170, 3, 149, 249, 82, 22, 102, 230, 110, 161, 58, 192, 215, 154, 111, 211, 218, 246, 156, 10, 76, 154, 7, 200, 146, 231, 194, 37, 83, 151, 53, 199, 153, 36, 194, 199, 114, 236, 81, 194, 255, 29, 69, 142, 180, 89, 177, 211, 45, 82, 181, 70, 91, 75, 34, 250, 5, 71, 206, 230, 142, 155, 11, 225, 240, 0, 237, 105, 125, 91, 203, 1, 88, 88, 12, 177, 188, 75]
Printed from wasi: This is from a main function
This is from a main function
The env vars are as follows.
PATH: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOSTNAME: wasm-demo-cgk9z
KUBERNETES_PORT_443_TCP_PROTO: tcp
KUBERNETES_PORT_443_TCP_PORT: 443
KUBERNETES_PORT_443_TCP_ADDR: 10.96.0.1
KUBERNETES_SERVICE_HOST: 10.96.0.1
KUBERNETES_SERVICE_PORT: 443
KUBERNETES_SERVICE_PORT_HTTPS: 443
KUBERNETES_PORT: tcp://10.96.0.1:443
KUBERNETES_PORT_443_TCP: tcp://10.96.0.1:443
HOME: /
The args are as follows.
/wasi_example_main.wasm
50000000
File content is This is in a file
```
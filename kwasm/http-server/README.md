# Run a WasmEdge HTTP server app with kwasm-operator

This demo will show how to run a WasmEdge HTTP server pod with kwasm-operater.

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

Check cluster status:

```
kubectl get all

NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   32s
```

## Prepare kubernetes configuration files

We will use the [wasmedge/example-wasi-http](https://hub.docker.com/r/wasmedge/example-wasi-http) image here.
Create a configuration file named `demo.yaml`. In this configuration, we will start 2 `wasmedge/example-wasi-http` pods and a load balancer:

```yaml
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: crun
handler: crun
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: demo-app
  template:
    metadata:
      labels:
        app: demo-app
      annotations:
        module.wasm.image/variant: compat-smart
    spec:
      containers:
      - name: demo-container
        image: wasmedge/example-wasi-http:latest
        ports:
        - containerPort: 1234
      runtimeClassName: crun
---
apiVersion: v1
kind: Service
metadata:
  name: demo-service
spec:
  type: LoadBalancer
  selector:
    app: demo-app
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 1234
```

## Apply configuration to start deployment

Start deployment and service:

```
kubectl apply -f demo.yaml

runtimeclass.node.k8s.io/crun created
deployment.apps/demo-deployment created
service/demo-service created
```

Check cluster status:

```
kubectl get all

NAME                                   READY   STATUS    RESTARTS   AGE
pod/demo-deployment-65d47875d4-8m5db   1/1     Running   0          9s
pod/demo-deployment-65d47875d4-nqn8x   1/1     Running   0          9s

NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
service/demo-service   LoadBalancer   10.96.210.184   <pending>     8080:30716/TCP   9s
service/kubernetes     ClusterIP      10.96.0.1       <none>        443/TCP          57s

NAME                              READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/demo-deployment   2/2     2            2           9s

NAME                                         DESIRED   CURRENT   READY   AGE
replicaset.apps/demo-deployment-65d47875d4   2         2         2       9s
```

Check the service:

```
kubectl port-forward service/demo-service 8080

Forwarding from 127.0.0.1:8080 -> 1234
Forwarding from [::1]:8080 -> 1234
```

```
curl -d name=WasmEdge localhost:8080

echo: name=WasmEdge
```

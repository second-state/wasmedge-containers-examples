# Running http_server example in CRI-O with WasmEdge support

## Quick start

Please following the CRI-O [crio/README.md](../README.md) in the example to setup CRI-O and crun.

## Run a simple WebAssembly app

With Wasm support crun can with directly with the http_server with-wasm-annotation. 
In this section, we will start off pulling the http_server WebAssembly-based container
image from Docker hub using CRI-O tools.

```bash
crictl pull docker.io/avengermojo/http_server:with-wasm-annotation
```

Next, we need to create two simple configuration files that specifies how
CRI-O should run this WebAssembly image in a sandbox. We already have those
two files [http_server_wasi.yaml](http_server_wasi.yaml) and [sandbox_config.yaml](sandbox_config.yaml).
You can just download them to your local directory as follows.

```bash
wget https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/crio/http_server/sandbox_config.yaml
wget https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/crio/http_server/http_server_wasi.yaml
```

Now you can use CRI-O to create a pod and a container using the specified configurations.

```bash
# Create the POD. Output will be different from example.
POD_ID=`sudo crictl runp sandbox_config.yaml`

# Echo the POD_ID to make sure it is completed
echo $POD_ID

# Create the container instance. Output will be different from example.
CONTAINER_ID=`sudo crictl create $POD_ID http_server_wasi.yaml sandbox_config.yaml`

# Echo the CONTAINER_ID to make sure it is completed
echo $CONTAINER_ID
```

Starting the container would execute the WebAssembly program.
List the container, the state should be `Created`

```bash
sudo crictl ps -a
```

Then you can start the http_server

```bash
# Start the container
sudo crictl start $CONTAINER_ID

# Check the container status again.
# You should see the http_server is in the Running state.
sudo crictl ps
```

Check the http_server ip with inspect and request the service with curl post

```bash
HTTP_IP=`sudo crictl inspect $CONTAINER_ID | grep IP.0 | cut -d: -f 2 | cut -d'"' -f 2`
gurl -d "param1=value1&param2=value2" -X POST http://$HTTP_IP:1234/post


echo param1=value1&param2=value2
```bash
If you can see the server echo back the value you input, then that's it!

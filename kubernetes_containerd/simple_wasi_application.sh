export KUBECONFIG=/var/run/kubernetes/admin.kubeconfig

sudo ./kubernetes/cluster/kubectl.sh run --restart=Never wasi-demo --image=hydai/wasm-wasi-example:with-wasm-annotation --annotations="module.wasm.image/variant=compat" --overrides='{"kind":"Pod", "apiVersion":"v1", "spec": {"hostNetwork": true}}' /wasi_example_main.wasm 50000000


export KUBECONFIG=/var/run/kubernetes/admin.kubeconfig

./kubernetes/cluster/kubectl.sh run --restart=Never http-server --image=avengermojo/http-server:with-wasm-annotation --annotations="module.wasm.image/variant=compat" --overrides='{"kind":"Pod", "apiVersion":"v1", "spec": {"hostNetwork": true}}'


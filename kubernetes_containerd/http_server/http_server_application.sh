export KUBECONFIG=/var/run/kubernetes/admin.kubeconfig

sudo ./kubernetes/cluster/kubectl.sh run --restart=Never http-server --image=avengermojo/http-server:with-wasm-annotation --annotations="module.wasm.image/variant=compat" --overrides='{"kind":"Pod", "apiVersion":"v1", "spec": {"hostNetwork": true}}'

sleep 60

echo -e "\n\nTesting\n\n"
curl -d "name=WasmEdge" -X POST http://127.0.0.1:1234
echo -e "\n\nFinished\n\n"
echo -e "Done!"


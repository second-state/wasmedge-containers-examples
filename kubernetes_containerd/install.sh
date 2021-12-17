git clone https://github.com/kubernetes/kubernetes.git
cd kubernetes/
git checkout v1.22.4
cd ../
echo -e "Installing etcd"
sudo apt-get install -y net-tools
sudo CGROUP_DRIVER=systemd CONTAINER_RUNTIME=remote CONTAINER_RUNTIME_ENDPOINT='unix:///var/run/containerd/containerd.sock' ./kubernetes/hack/install-etcd.sh
export PATH="/home/${USER}/kubernetes/third_party/etcd:${PATH}"
sudo cp -rp ./kubernetes/third_party/etcd/etcd* /usr/local/bin/
echo -e "Building and running k8s with containerd"
sudo apt-get install -y build-essential
sudo -b CGROUP_DRIVER=systemd CONTAINER_RUNTIME=remote CONTAINER_RUNTIME_ENDPOINT='unix:///var/run/containerd/containerd.sock' ./kubernetes/hack/local-up-cluster.sh


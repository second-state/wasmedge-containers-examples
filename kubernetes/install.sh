#!/bin/bash
sudo apt-get update
echo -e "Running Wasm in Kubernetes (k8s) ..."
echo -e "Installing Go"
wget https://golang.org/dl/go1.17.3.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.17.3.linux-amd64.tar.gz
echo -e "\nexport PATH=$PATH:/usr/local/go/bin" | tee -i -a /home/${USER}/.profile
source /home/${USER}/.profile
echo -e "Defaults        secure_path=\"/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin\"" | sudo tee -i /etc/sudoers.d/gofile
echo -e "Cloning Kubernetes ..."
git clone https://github.com/kubernetes/kubernetes.git
cd kubernetes/
git checkout v1.22.2
cd ../
echo -e "Installing etcd"
sudo CGROUP_DRIVER=systemd CONTAINER_RUNTIME=remote CONTAINER_RUNTIME_ENDPOINT='unix:///var/run/crio/crio.sock' ./kubernetes/hack/install-etcd.sh
export PATH="/home/${USER}/kubernetes/third_party/etcd:${PATH}"
sudo cp -rp ./kubernetes/third_party/etcd/etcd* /usr/local/bin/
echo -e "Building and running k8s with CRI-O"
sudo apt-get install -y build-essential
nohup sudo -b CGROUP_DRIVER=systemd CONTAINER_RUNTIME=remote CONTAINER_RUNTIME_ENDPOINT='unix:///var/run/crio/crio.sock' ./kubernetes/hack/local-up-cluster.sh > k8s.log 2>&1

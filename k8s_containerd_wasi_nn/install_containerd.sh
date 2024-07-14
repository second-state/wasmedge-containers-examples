#!/bin/bash

export WASMEDGE_VERSION="0.13.5"

echo -e "Starting installation ..."
sudo apt update
export VERSION="1.5.7"
echo -e "Version: $VERSION"
echo -e "Installing libseccomp2 ..."
sudo apt install -y libseccomp2
echo -e "Installing wget"
sudo apt install -y wget

wget https://github.com/containerd/containerd/releases/download/v${VERSION}/cri-containerd-cni-${VERSION}-linux-amd64.tar.gz
wget https://github.com/containerd/containerd/releases/download/v${VERSION}/cri-containerd-cni-${VERSION}-linux-amd64.tar.gz.sha256sum
sha256sum --check cri-containerd-cni-${VERSION}-linux-amd64.tar.gz.sha256sum

sudo tar --no-overwrite-dir -C / -xzf cri-containerd-cni-${VERSION}-linux-amd64.tar.gz
sudo systemctl daemon-reload

# change containerd conf to use crun as default
sudo mkdir -p /etc/containerd/
sudo bash -c "containerd config default > /etc/containerd/config.toml"
wget https://raw.githubusercontent.com/second-state/wasmedge-containers-examples/main/containerd/containerd_config.diff
sudo patch -d/ -p0 < containerd_config.diff
sudo systemctl start containerd

echo -e "Installing WasmEdge"
if [ -f install.sh ]
then
    rm -rf install.sh
fi
wget -q https://raw.githubusercontent.com/WasmEdge/WasmEdge/master/utils/install.sh
sudo chmod a+x install.sh

echo -e "Use WasmEdge: $WASMEDGE_VERSION"
sudo ./install.sh --path="/usr/local" --version="$WASMEDGE_VERSION" --dist="manylinux2014"

rm -rf install.sh
echo -e "Building and installing crun"
sudo apt install -y make git gcc build-essential pkgconf libtool libsystemd-dev libprotobuf-c-dev libcap-dev libseccomp-dev libyajl-dev go-md2man libtool autoconf python3 automake

echo -e "Use plugin-enabled Crun"
git clone --branch enable_plugin  --single-branch https://github.com/hydai/crun

cd crun || exit
./autogen.sh
./configure --with-wasmedge
make
sudo make install


sudo systemctl restart containerd
echo -e "Finished"

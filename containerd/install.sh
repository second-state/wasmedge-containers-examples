#!/bin/bash

export WASMEDGE_VERSION=""
export CRUN_VERSION=""
export ZH="FALSE"

for opt in "$@"; do
  case $opt in
    -w=*|--wasmedge=*)
      export WASMEDGE_VERSION="${opt#*=}"
      shift
      ;;
    -c=*|--crun=*)
      export CRUN_VERSION="${opt#*=}"
      shift
      ;;
    --zh=*)
      export ZH="${opt#*=}"
      shift
      ;;
    *)
      ;;
  esac
done

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
if [[ "$ZH" = "TRUE" ]]; then
    echo -e "Use ZH mirror"
    sudo sed -i 's/k8s.gcr.io\/pause:3.5/mirrorgooglecontainers\/pause:3.5/g' /etc/containerd/config.toml
fi
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

if [[ "$WASMEDGE_VERSION" = "" ]]; then
    echo -e "Use latest WasmEdge release"
    sudo ./install.sh --path="/usr/local"
else
    echo -e "Use WasmEdge: $WASMEDGE_VERSION"
    sudo ./install.sh --path="/usr/local" --version=$WASMEDGE_VERSION
fi

rm -rf install.sh
echo -e "Building and installing crun"
sudo apt install -y make git gcc build-essential pkgconf libtool libsystemd-dev libprotobuf-c-dev libcap-dev libseccomp-dev libyajl-dev go-md2man libtool autoconf python3 automake

if [[ "$CRUN_VERSION" = "" ]]; then
    echo -e "Use latest master of Crun"
    git clone https://github.com/containers/crun
else
    echo -e "Use Crun: $CRUN_VERSION"
    echo -e "Downloading crun-${CRUN_VERSION}.tar.gz"
    wget https://github.com/containers/crun/releases/download/${CRUN_VERSION}/crun-${CRUN_VERSION}.tar.gz
    tar --no-overwrite-dir -xzf crun-${CRUN_VERSION}.tar.gz
    mv crun-${CRUN_VERSION} crun
fi

cd crun
./autogen.sh
./configure --with-wasmedge
make
sudo make install


sudo systemctl restart containerd
echo -e "Finished"

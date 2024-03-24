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

echo -e "Installing podman"
sudo apt -y update
sudo apt -y install podman

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

#!/bin/bash
echo -e "Starting installation ..."
sudo apt update
export OS="xUbuntu_20.04"
export VERSION="1.21"
echo -e "OS: $OS"
echo -e "Version: $VERSION"
echo -e "Installing libseccomp2 ..."
sudo apt install -y libseccomp2
# Set download URL that we are adding to sources.list.d
export ADD1="deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /"
export DEST1="/etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list"
echo -e "Adding \n$ADD1 \nto \n$DEST1"
export ADD2="deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /"
export DEST2="/etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list"
echo -e "Adding \n$ADD2 \nto \n$DEST2"
sudo rm -rf "$DEST1"
sudo rm -rf "$DEST2"
sudo touch "$DEST1"
sudo touch "$DEST2"
if [ -f "$DEST1" ]
then 
    echo "$ADD1" | sudo tee -i "$DEST1"
    echo "Success writing to $DEST1"
else
	echo "Error writing to $DEST1"
	exit 2
fi

if [ -f "$DEST2" ]
then 
    echo "$ADD2" | sudo tee -i "$DEST2"
    echo "Success writing to $DEST2"
else
	echo "Error writing to $DEST2"
	exit 2
fi
echo -e "Installing wget"
sudo apt install -y wget
if [ -f Release.key ]
then 
    rm -rf Release.key
fi
echo -e "Fetching Release.key"
wget "https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/Release.key"
echo -e "Adding Release.key"
sudo apt-key add Release.key
echo -e "Deleting Release.key"
rm -rf Release.key
echo -e "Fetching Release.key"
wget "https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key"
echo -e "Adding Release.key"
sudo apt-key add Release.key
echo -e "Removing Release.key"
rm -rf Release.key
sudo apt update
sudo apt install -y criu
sudo apt install -y libyajl2
sudo apt install -y cri-o
sudo apt install -y cri-o-runc
sudo apt install -y cri-tools
sudo apt install -y containernetworking-plugins
echo -e "Installing WasmEdge"
if [ -f install.sh ]
then 
    rm -rf install.sh
fi
wget -q https://raw.githubusercontent.com/WasmEdge/WasmEdge/master/utils/install.sh
sudo chmod a+x install.sh
sudo ./install.sh --path="/usr/local"
rm -rf install.sh
echo -e "Building and installing crun"
sudo apt install -y make git gcc build-essential pkgconf libtool libsystemd-dev libprotobuf-c-dev libcap-dev libseccomp-dev libyajl-dev go-md2man libtool autoconf python3 automake
git clone https://github.com/containers/crun
cd crun
./autogen.sh
./configure --with-wasmedge
make
sudo make install
# sudo cp -f crun /usr/lib/cri-o-runc/sbin/runc

# wget https://github.com/second-state/crunw/releases/download/1.0-wasmedge/crunw_1.0-wasmedge+dfsg-1_amd64.deb
# sudo dpkg -i --force-overwrite crunw_1.0-wasmedge+dfsg-1_amd64.deb
# rm -rf crunw_1.0-wasmedge+dfsg-1_amd64.deb
# Write config
echo -e "[crio.runtime]\ndefault_runtime = \"crun\"\n" | sudo tee -i /etc/crio/crio.conf
echo -e "\n# Add crun runtime here\n[crio.runtime.runtimes.crun]\nruntime_path = \"/usr/local/bin/crun\"\nruntime_type = \"oci\"\nruntime_root = \"/run/crun\"\n" | sudo tee -i -a /etc/crio/crio.conf.d/01-crio-runc.conf

sudo systemctl restart crio
echo -e "Finished"

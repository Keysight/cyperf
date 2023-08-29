#!/bin/bash
sudo apt-get update
sudo apt-get install -y unzip
sudo apt-get install -y wget
sudo apt-get install -y ansible
sudo apt-get install -y sshpass
sudo apt-get install -y curl



# Download terraform 
export VER="0.12.29"
wget https://releases.hashicorp.com/terraform/${VER}/terraform_${VER}_linux_amd64.zip
unzip terraform_${VER}_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Downlaod govc
#wget https://github.com/vmware/govmomi/releases/download/v0.23.0/govc_linux_amd64.gz
curl -L "https://github.com/vmware/govmomi/releases/download/v0.23.0/govc_linux_amd64.gz" | gunzip > /usr/local/bin/govc
chmod +x /usr/local/bin/govc

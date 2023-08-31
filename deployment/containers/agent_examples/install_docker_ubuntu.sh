#!/bin/sh

# Reference: https://docs.docker.com/engine/install/ubuntu/
#Set up the repository
#Update the apt package index and install packages to allow apt to use a repository over HTTPS:


 sudo apt-get -y update
 sudo apt-get -y install \
    ca-certificates \
    curl \
    gnupg

#Add Docker’s official GPG key:

sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg


#Use the following command to set up the repository:

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get -y update
sudo chmod a+r /etc/apt/keyrings/docker.gpg
sudo apt-get -y update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
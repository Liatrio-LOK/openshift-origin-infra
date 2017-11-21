#!/bin/bash

sudo yum -y update

# Docker Setup

# Configure docker storage 
# See https://docs.openshift.org/latest/install_config/install/host_preparation.html#configuring-docker-storage
echo "
DEVS=/dev/xvdf
VG=docker-vg
" | sudo tee /etc/sysconfig/docker-storage-setup
sudo docker-storage-setup

# Install docker-ce
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker

# GlusterFS Prep
sudo yum -y install glusterfs-fuse
sudo yum -y update glusterfs-fuse

# Other
sudo yum install -y NetworkManager
sudo systemctl start NetworkManager


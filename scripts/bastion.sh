#!/bin/bash

sudo yum update -y
sudo yum install -y epel-release
sudo yum install -y ansible
sudo yum install -y git

git clone -b release-3.6 https://github.com/openshift/openshift-ansible.git


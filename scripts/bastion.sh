#!/bin/bash

sudo yum update -y
sudo yum install -y epel-release ansible git httpd-tools java-1.8.0-openjdk-headless

git clone -b release-3.6 https://github.com/openshift/openshift-ansible.git


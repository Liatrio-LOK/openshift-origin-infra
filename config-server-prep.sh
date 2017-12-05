#!/bin/bash

sudo yum update -y

sudo yum install epel-release -y

sudo yum install ansible git -y

git clone --recursive https://github.com/Liatrio-LOK/openshift-origin-infra

cd openshift-origin-infra

ansible-playbook -i inventory openshift-ansible/playbooks/byo/config.yml

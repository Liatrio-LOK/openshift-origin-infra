# Openshift Origin Infrastructure

## About

This repo contains terraform templates and ansible inventories designed to emulate
the official [Red Hat OpenShift Container
Platform on the AWS Cloud](https://s3.amazonaws.com/quickstart-reference/redhat/openshift/latest/doc/red-hat-openshift-on-the-aws-cloud.pdf)
without requiring a paid redhat enterprise subscription.

## Current features

* Single AZ openshift cluster
* GitHub oauth authentication
* Container native storage (glusterfs storage class for persistent volumes)


## Requirements

* terraform (tested with v0.10.5)
* ansible (teste with v2.3.1.0)

## Provisioning

```sh
# Create a GitHub oauth application for the cluster
# Insert client id and secret key into the inventory
# See https://docs.openshift.org/latest/install_config/configuring_authentication.html#GitHub
terraform init
terraform apply
ansible-playbook -i inventory openshift-ansible/playbooks/byo/config.yml
```

### TODO
* Parameterize ansible inventory and terraform template
* Support for user-provided ssl certs
* Dedicated VPC spanning 3 AZs
* 3 Master instances spanning 3 AZs behind an elastic loadbalancer
* Dedicated infra instances  spanning 3 AZs
* Dedicated etcd instances spanning 3 AZs
* Prevent non-admin scheduling on master nodes
* Move openshift infra to private subnets and use public-facing ansible config server.
* Logging stack (TBD)
* System monitoring stack (TBD)


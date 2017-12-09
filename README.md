# Openshift Origin Infrastructure

## About

This repo contains terraform templates and ansible inventories designed to emulate
the official [Red Hat OpenShift Container
Platform on the AWS Cloud](https://s3.amazonaws.com/quickstart-reference/redhat/openshift/latest/doc/red-hat-openshift-on-the-aws-cloud.pdf)
without requiring a paid redhat enterprise subscription.

## Current features

* Multi-AZ OpenShift 3.6.1 cluster
* Single master per instance per AZ 
* Single dedicated etcd instance per AZ
* Many node instances distributed evenly through AZs
* Container native storage (glusterfs storage class for persistent volumes)
* Provide ssl certs through AWS Certificate Manager
* GitHub OAuth authentication

## Requirements

* Terraform (tested with v0.10.5)

## Provisioning

1. Create a Route53 domain
2. Create an ssl cert through AWS Certificate manager for `console.${cluster_prefix}.${domain}`
3. Create a GitHub OAuth app and org for authentication (See https://docs.openshift.org/latest/install_config/configuring_authentication.html#GitHub)
4. Create a tfvars file (see example.tfvars)
5. Modify *scripts/configure-openshift* to add user permissions, etc. with the `oc` command after cluster setup (runs as system:admin). 
6. Apply the terraform template:

```sh
$ ssh-add /path/to/private/key.pem 
$ terraform init 
$ terraform apply -var-file="myvars.tfvars"
```

## Shelling into a master host
```sh
# For cluster_prefix="openshift" and domain="example.com"
$ ssh-add /path/to/private/key
$ ssh -A -J centos@bastion.openshift.example.com centos@master0.openshift.example.com
```

## Scaling up nodes

1. Increase `node_count` variable to new count
2. Apply the new configuration to terraform:
```sh
$ ssh-add /path/to/private/key
$ terraform plan -var-file="myvars.tfvars" # Make sure this looks ok!
$ terraform apply -var-file="myvars.tfvars"
```
3. Follow the [Adding Hosts Using the Advanced Install](https://docs.openshift.com/container-platform/latest/install_config/adding_hosts_to_existing_cluster.html#adding-nodes-advanced)
	* A copy of the inventory was saved to this directory during the initial install (`${cluster_prefix}-inventory}`)
	* New node hostnames will be `node[oldcount:newcount].${cluster_prefix}.${domain}`. If you are scaling up from 3 to 5 nodes, this would look like `node[3:4].openshift.example.com`. 
	* Copy the inventory to the bastion host, `bastion.${cluster_prefix}.${domain}`, which has an installation of Ansible. Shell into the bastion to execute the scaleup playbook. 
	* Remember to delete the inventory file on the bastion since it contains sensitive information. 
	* Update your local inventory's [nodes] group to represent the new cluster state.

## Scaling down nodes
1. Decrease `node_count` variable to new count.
2. Apply the new configuration to terraform:
```sh
$ ssh-add /path/to/private/key
$ terraform plan -var-file="myvars.tfvars" # Make sure this looks ok!
$ terraform apply -var-file="myvars.tfvars"
```

### TODO
* ~~Parameterize ansible inventory and terraform template~~
* ~~Support for user-provided ssl certs~~
* ~~Dedicated VPC spanning 3 AZs~~
* ~~3 Master instances spanning 3 AZs behind a load balancer~~
* ~~Dedicated etcd instances spanning 3 AZs~~
* ~~Move openshift infra to private subnets and use public-facing ansible config server.~~
* Dedicated infra instances spanning 3 AZs
* Prevent non-admin scheduling on master nodes
* Logging stack (TBD)
* System monitoring stack (TBD)
* Dynamic routes with Route53 plugin


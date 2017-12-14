# Create an OSEv3 group that contains the masters and nodes groups
[OSEv3:children]
masters
nodes
etcd
glusterfs

# host group for masters
[masters]
${master_hosts}

# host group for etcd
[etcd]
${etcd_hosts}

# host group for nodes, includes region info
[nodes]
${node_hosts}

[nodes:vars] # TODO: Create dedicated infra nodes
openshift_node_labels="{'region': 'infra','zone': 'default'}" 
openshift_schedulable=true

[glusterfs]
${node_hosts}

[glusterfs:vars]
glusterfs_devices=[ "/dev/xvdg" ]

# Set variables common for all OSEv3 hosts
[OSEv3:vars]

# Connection
ansible_ssh_user=centos
ansible_become=true

# Cluster
openshift_deployment_type=origin
openshift_release=3.6.1
openshift_master_cluster_method=native
# enable ntp on masters to ensure proper failover
openshift_clock_enabled=true

# API/Console
openshift_master_cluster_public_hostname=${cluster_prefix}.${domain}
openshift_master_console_port=443
openshift_master_api_port=443
openshift_master_default_subdomain=${cluster_prefix}.${domain}

# GitHub OAuth
openshift_master_identity_providers=[{'name': 'github', 'login': 'true', 'challenge': 'false', 'kind': 'GitHubIdentityProvider', 'clientID': '${github_oauth_client_id}', 'clientSecret': '${github_oauth_client_secret}', 'organizations': ['${github_oauth_org}']}]

# Metrics
openshift_metrics_image_version=v3.6.1
openshift_metrics_cassandra_storage_type=dynamic

# Logging



#
# Runs openshift-ansible playbook and configured openshift.
#

# Render an inventory file to use with the byo playbook
data "template_file" "ansible_inventory" {
  template = "${file("${path.module}/templates/inventory.tpl")}"

  vars {
    domain         = "${var.domain}"
    cluster_prefix = "${var.cluster_prefix}"

    bastion_host = "${aws_instance.bastion.public_ip}"
    master_hosts = "${join("\n", aws_instance.master.*.private_ip)}"
    etcd_hosts   = "${join("\n", aws_instance.etcd.*.private_ip)}"
    node_hosts   = "${join("\n", aws_instance.nodes.*.private_ip)}"

    github_oauth_client_id     = "${var.github_oauth_client_id}"
    github_oauth_client_secret = "${var.github_oauth_client_secret}"
    github_oauth_org           = "${var.github_oauth_org}"
  }
}

# Save a copy of inventory locally
resource "local_file" "inventory" {
  content  = "${data.template_file.ansible_inventory.rendered}"
  filename = "${path.module}/${var.cluster_prefix}-inventory"
}

resource "null_resource" "run_playbook" {

  depends_on = ["aws_instance.master", "aws_instance.etcd", "aws_instance.nodes"]

  connection {
    type         = "ssh"
    user         = "centos"
    host         = "${aws_instance.bastion.public_ip}"
    agent        = true
  }

  provisioner "file" {
    content     = "${data.template_file.ansible_inventory.rendered}"
    destination = "/home/centos/inventory"
  }

  # Run the playbook
  provisioner "remote-exec" {
    inline = [
      "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i /home/centos/inventory openshift-ansible/playbooks/byo/config.yml",
    ]
  }

  # Delete sensitive inventory data
  /* TODO: Fix this
  provisioner "file" {
    content     = ""
    destination = "/home/centos/inventory"
  }
  */
}

resource "null_resource" "configure_openshift" {
  provisioner "remote-exec" {
    script = "${path.module}/scripts/configure-openshift.sh"

    connection {
      type         = "ssh"
      user         = "centos"
      agent        = true
      bastion_host = "${aws_instance.bastion.public_ip}"
      host         = "${aws_instance.master.0.private_ip}"
    }
  }
}

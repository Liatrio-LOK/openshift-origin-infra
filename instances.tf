resource "aws_instance" "bastion" {
  ami                    = "${var.ami}"
  instance_type          = "m4.xlarge" # Ansible takes a lot of memory
  key_name               = "${var.aws_key_pair}"
  subnet_id              = "${aws_subnet.public.0.id}"
  vpc_security_group_ids = ["${aws_security_group.bastion.id}", "${aws_security_group.internal.id}"]

  provisioner "remote-exec" {
    script = "${path.module}/scripts/bastion.sh" 

    connection {
      type         = "ssh"
      user         = "centos"
    }
  }

  tags {
    Name = "bastion.${var.cluster_prefix}.${var.domain}"
    group = "${var.cluster_prefix}-terraform-created"
  }
}

resource "aws_instance" "master" {
  ami                    = "${var.ami}"
  instance_type          = "m4.xlarge"
  key_name               = "${var.aws_key_pair}"
  count                  = "${var.az_count}"                                                        # 1 master per subnet
  subnet_id              = "${element(aws_subnet.private.*.id, count.index)}"
  vpc_security_group_ids = ["${aws_security_group.master.id}", "${aws_security_group.internal.id}"]

  root_block_device {
    volume_type = "gp2"
    volume_size = "40"
  }

  # Device for Docker storage backend to replace default thin pool
  # See https://docs.openshift.org/latest/install_config/install/host_preparation.html#configuring-docker-storage
  ebs_block_device {
    volume_type = "gp2"
    volume_size = 20
    device_name = "/dev/sdf"
  }

  provisioner "remote-exec" {
    script = "${path.module}/scripts/host-prep.sh"

    connection {
      type         = "ssh"
      user         = "centos"
      bastion_host = "${aws_instance.bastion.public_ip}"
    }
  }

  tags {
    Name = "master${count.index}.${var.cluster_prefix}.${var.domain}"
    group = "${var.cluster_prefix}-terraform-created"
  }
}

resource "aws_instance" "etcd" {
  ami                    = "${var.ami}"
  instance_type          = "m4.xlarge"
  key_name               = "${var.aws_key_pair}"
  count                  = "${var.az_count}"                                                        # 1 etcd per subnet
  subnet_id              = "${element(aws_subnet.private.*.id, count.index)}"
  vpc_security_group_ids = ["${aws_security_group.nodes.id}", "${aws_security_group.internal.id}"]

  root_block_device {
    volume_type = "gp2"
    volume_size = "40"
  }

  # Device for Docker storage backend to replace default thin pool
  # See https://docs.openshift.org/latest/install_config/install/host_preparation.html#configuring-docker-storage
  ebs_block_device {
    volume_type = "gp2"
    volume_size = 20
    device_name = "/dev/sdf"
  }

  provisioner "remote-exec" {
    script = "${path.module}/scripts/host-prep.sh"

    connection {
      type         = "ssh"
      user         = "centos"
      bastion_host = "${aws_instance.bastion.public_ip}"
    }
  }

  tags {
    Name = "etcd${count.index}.${var.cluster_prefix}.${var.domain}"
    group = "${var.cluster_prefix}-terraform-created"
  }
}

resource "aws_instance" "nodes" {
  ami                    = "${var.ami}"
  instance_type          = "m4.xlarge"
  key_name               = "${var.aws_key_pair}"
  vpc_security_group_ids = ["${aws_security_group.nodes.id}", "${aws_security_group.internal.id}"]
  count                  = "${var.node_count}"
  subnet_id              = "${element(aws_subnet.private.*.id, count.index)}"

  root_block_device {
    volume_type = "gp2"
    volume_size = "40"
  }

  # Device for Docker storage backend to replace default thin pool
  # See https://docs.openshift.org/latest/install_config/install/host_preparation.html#configuring-docker-storage
  ebs_block_device {
    volume_type = "gp2"
    volume_size = 40
    device_name = "/dev/sdf"
  }

  # GlusterFS storage (see https://goo.gl/rmwSD8)
  ebs_block_device {
    volume_type = "gp2"
    volume_size = 100        # Minimum allowable size for gfs node
    device_name = "/dev/sdg"
  }

  provisioner "remote-exec" {
    script = "${path.module}/scripts/host-prep.sh"

    connection {
      type = "ssh"
      host = "${self.private_ip}"
      user = "centos"
      bastion_host = "${aws_instance.bastion.public_ip}"
      agent        = true
    }
  }

  tags {
    Name = "node${count.index}.${var.cluster_prefix}.${var.domain}"
    group = "${var.cluster_prefix}-terraform-created"
  }
}

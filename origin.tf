provider "aws" {
  region = "us-east-1"
}

# Variables 

variable aws_key_pair {
  default = "eddieb"
}

variable private_key_path {
  default = "~/.ssh/id_rsa"
}

variable ami {
  default = "ami-ae7bfdb8" # CentOS 7 us-east-1
}

variable node_count {
  default = 2
}

# Instances

resource "aws_instance" "master" {
  ami                    = "${var.ami}"
  instance_type          = "m4.xlarge"
  key_name               = "${var.aws_key_pair}"
  vpc_security_group_ids = ["${aws_security_group.master.id}", "${aws_security_group.internal.id}"]

  root_block_device {
    volume_type = "gp2"
    volume_size = "80"
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
    volume_size = 100 # Minimum allowable size for gfs node
    device_name = "/dev/sdg"
  }

  provisioner "remote-exec" {
    script = "${path.module}/host-prep.sh" # 

    connection {
      type        = "ssh"
      user        = "centos"
      private_key = "${file("${var.private_key_path}")}"
    }
  }
  tags {
    Name = "master.os-sandbox.liatr.io"
  }
}

resource "aws_instance" "nodes" {
  ami                    = "${var.ami}"
  instance_type          = "m4.xlarge"
  key_name               = "${var.aws_key_pair}"
  vpc_security_group_ids = ["${aws_security_group.nodes.id}", "${aws_security_group.internal.id}"]
  count                  = "${var.node_count}"

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
    volume_size = 100 # Minimum allowable size for gfs node
    device_name = "/dev/sdg"
  }

  provisioner "remote-exec" {
    script = "${path.module}/host-prep.sh"

    connection {
      type        = "ssh"
      user        = "centos"
      private_key = "${file("${var.private_key_path}")}"
    }
  }
  tags {
    Name = "node${count.index}.os-sandbox.liatr.io"
  }
}

# Security Groups

resource "aws_security_group" "internal" {
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = "true"
  }
}

resource "aws_security_group" "master" {
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "nodes" {
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# DNS

data "aws_route53_zone" "liatrio" {
  name = "liatr.io"
}

resource "aws_route53_record" "master" {
  zone_id = "${data.aws_route53_zone.liatrio.zone_id}"
  name    = "master.os-sandbox.liatr.io"
  type    = "A"
  ttl     = 300
  records = ["${aws_instance.master.public_ip}"]
}

resource "aws_route53_record" "nodes" {
  zone_id = "${data.aws_route53_zone.liatrio.zone_id}"
  count   = "${var.node_count}"
  name    = "node${count.index}.os-sandbox.liatr.io"
  type    = "A"
  ttl     = 300
  records = ["${element(aws_instance.nodes.*.public_ip, count.index)}"]
}


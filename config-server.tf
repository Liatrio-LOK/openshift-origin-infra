# Instances

resource "aws_instance" "config-server" {
  ami                    = "${var.ami}"
  instance_type          = "m4.xlarge"
  key_name               = "${var.aws_key_pair}"
  vpc_security_group_ids = ["${aws_security_group.config-server.id}", "${aws_security_group.internal.id}"]

  root_block_device {
    volume_type = "gp2"
    volume_size = "20"
  }

  provisioner "remote-exec" {
    script = "${path.module}/config-server-prep.sh"

    connection {
      type        = "ssh"
      user        = "centos"
      private_key = "${file("${var.private_key_path}")}"
    }
  }
  tags {
    Name = "config.os-sandbox.liatr.io"
  }
}

# Security Groups

resource "aws_security_group" "config-server" {
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

# DNS

resource "aws_route53_record" "config-server" {
  zone_id = "${data.aws_route53_zone.liatrio.zone_id}"
  name    = "config.os-sandbox.liatr.io"
  type    = "A"
  ttl     = 300
  records = ["${aws_instance.config-server.public_ip}"]
}

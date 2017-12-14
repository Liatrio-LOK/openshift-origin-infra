data "aws_route53_zone" "domain" {
  name = "${var.domain}"
}

resource "aws_route53_record" "cluster" {
  zone_id = "${data.aws_route53_zone.domain.zone_id}"
  name    = "${var.cluster_prefix}.${var.domain}"
  type    = "A"

  alias {
    name                   = "${aws_lb.cluster.dns_name}"
    zone_id                = "${aws_lb.cluster.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "cluster_wildcard" {
  zone_id = "${data.aws_route53_zone.domain.zone_id}"
  name    = "*.${var.cluster_prefix}.${var.domain}"
  type    = "A"

  alias {
    name                   = "${aws_lb.cluster.dns_name}"
    zone_id                = "${aws_lb.cluster.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "bastion" {
  zone_id = "${data.aws_route53_zone.domain.zone_id}"
  name    = "bastion.${var.cluster_prefix}.${var.domain}"
  type    = "A"
  ttl     = 300
  records = ["${aws_instance.bastion.public_ip}"]
}

resource "aws_route53_record" "master" {
  zone_id = "${data.aws_route53_zone.domain.zone_id}"
  count   = "${var.az_count}"
  name    = "master${count.index}.${var.cluster_prefix}.${var.domain}"
  type    = "A"
  ttl     = 300
  records = ["${element(aws_instance.master.*.private_ip, count.index)}"]
}

resource "aws_route53_record" "etcd" {
  zone_id = "${data.aws_route53_zone.domain.zone_id}"
  count   = "${var.az_count}"
  name    = "etcd${count.index}.${var.cluster_prefix}.${var.domain}"
  type    = "A"
  ttl     = 300
  records = ["${element(aws_instance.etcd.*.private_ip, count.index)}"]
}

resource "aws_route53_record" "nodes" {
  zone_id = "${data.aws_route53_zone.domain.zone_id}"
  count   = "${var.node_count}"
  name    = "node${count.index}.${var.cluster_prefix}.${var.domain}"
  type    = "A"
  ttl     = 300
  records = ["${element(aws_instance.nodes.*.private_ip, count.index)}"]
}

# For internal routing to heketi pod - must point to infra nodes!
resource "aws_route53_record" "heketi-storage-glusterfs" {
  zone_id = "${data.aws_route53_zone.domain.zone_id}"
  name    = "heketi-storage-glusterfs.${var.cluster_prefix}.${var.domain}"
  type    = "A"
  ttl     = 300
  records = ["${aws_instance.nodes.*.private_ip}"]
}


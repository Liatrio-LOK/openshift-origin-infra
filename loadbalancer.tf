data "aws_acm_certificate" "cluster" {
  domain   = "${var.cluster_prefix}.${var.domain}"
  statuses = ["ISSUED"]
}

resource "aws_lb" "cluster" {
  name            = "${var.cluster_prefix}"
  internal        = false
  security_groups = ["${aws_security_group.lb.id}"]
  subnets         = ["${aws_subnet.public.*.id}"]

  enable_deletion_protection = false # for now

  /* TODO
  access_logs {
    bucket = "${aws_s3_bucket.lb_logs.bucket}"
    prefix = "test-lb"
  }
  */

  tags {
    Name = "${var.cluster_prefix}"
    group = "${var.cluster_prefix}-terraform-created"
  }
}

resource "aws_lb_target_group" "cluster" {
  name     = "${var.cluster_prefix}"
  vpc_id   = "${aws_vpc.cluster_vpc.id}"
  port     = 443
  protocol = "HTTPS"
  # TODO: Health Check (https://www.terraform.io/docs/providers/aws/r/lb_target_group.html#health_check)
}

resource "aws_lb_target_group_attachment" "master" {
  count            = "${var.az_count}"
  target_group_arn = "${aws_lb_target_group.cluster.arn}"
  target_id        = "${element(aws_instance.master.*.id, count.index)}"
  port             = 443
}

resource "aws_lb_listener" "cluster" {
  load_balancer_arn = "${aws_lb.cluster.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${data.aws_acm_certificate.cluster.arn}"

  default_action {
    target_group_arn = "${aws_lb_target_group.cluster.arn}"
    type             = "forward"
  }
}

/*
   Above is the load balancer settings for the console (masters)
   Below is the load balancer settings for the apps (nodes)
*/

/*data "aws_acm_certificate" "apps" {
  domain   = "*.${var.cluster_prefix}.${var.domain}"
  statuses = ["ISSUED"]
}*/

resource "aws_lb" "apps" {
  name            = "apps-${var.cluster_prefix}"
  internal        = false
  security_groups = ["${aws_security_group.lb.id}"]
  subnets         = ["${aws_subnet.public.*.id}"]

  enable_deletion_protection = false # for now

  /* TODO
  access_logs {
    bucket = "${aws_s3_bucket.lb_logs.bucket}"
    prefix = "test-lb"
  }
  */

  tags {
    Name = "apps.${var.cluster_prefix}"
    group = "${var.cluster_prefix}-terraform-created"
  }
}

resource "aws_lb_target_group" "apps" {
  name     = "apps-${var.cluster_prefix}"
  vpc_id   = "${aws_vpc.cluster_vpc.id}" # this is fine?
  port     = 443
  protocol = "HTTPS"
  # TODO: Health Check (https://www.terraform.io/docs/providers/aws/r/lb_target_group.html#health_check)
}

resource "aws_lb_target_group_attachment" "node" {
  count            = "${var.az_count}"
  target_group_arn = "${aws_lb_target_group.apps.arn}"
  target_id        = "${element(aws_instance.nodes.*.id, count.index)}"
  port             = 443
}

resource "aws_lb_listener" "apps" {
  load_balancer_arn = "${aws_lb.apps.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${data.aws_acm_certificate.cluster.arn}"

  default_action {
    target_group_arn = "${aws_lb_target_group.apps.arn}"
    type             = "forward"
  }
}


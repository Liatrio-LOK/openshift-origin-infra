#
# To understand public/private subnet routing better, read these links:
#
#   https://stackoverflow.com/questions/38690012/aws-vpc-internet-gateway-vs-nat
#   http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/vpc-nat-gateway.html
#   https://www.terraform.io/docs/providers/aws/r/route_table.html
#   http://blog.kaliloudiaby.com/index.php/terraform-to-provision-vpc-on-aws-amazon-web-services/
#

data "aws_availability_zones" "available" {}

# Assert that enough availability zones exist in the region
/* Hacky way to do asserts in terraform, doesn't quite work.
resource "null_resource" "az_check" {
  count = "${length(data.aws_availability_zones.available.names) >= var.az_count ? 0 : 1}"
  "ERROR: Not enough availability zones in this region" = true
}
*/

resource "aws_vpc" "cluster_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true # Openshift uses hostnames to connect instances

  tags {
    Name = "${var.cluster_prefix}"
    group = "${var.cluster_prefix}-terraform-created"
  }
}

resource "aws_internet_gateway" "public_gateway" {
  vpc_id = "${aws_vpc.cluster_vpc.id}"

  tags {
    Name = "${var.cluster_prefix}"
    group = "${var.cluster_prefix}-terraform-created"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = "${aws_vpc.cluster_vpc.id}"
  count                   = "${var.az_count}"
  availability_zone       = "${element(data.aws_availability_zones.available.names, count.index)}"
  cidr_block              = "10.0.${count.index}.0/24" # Avoid conflicts with private subnets
  map_public_ip_on_launch = true

  tags {
    Name = "${var.cluster_prefix}-public-${count.index}"
    group = "${var.cluster_prefix}-terraform-created"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.cluster_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.public_gateway.id}"
  }

  tags {
    Name = "${var.cluster_prefix}-public"
    group = "${var.cluster_prefix}-terraform-created"
  }
}

resource "aws_route_table_association" "public" {
  count          = "${var.az_count}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_subnet" "private" {
  vpc_id            = "${aws_vpc.cluster_vpc.id}"
  count             = "${var.az_count}"
  availability_zone = "${element(data.aws_availability_zones.available.names, count.index)}"
  cidr_block        = "10.0.${255 - count.index}.0/24" # Avoid conflicts with public subnets

  tags {
    Name = "${var.cluster_prefix}-private-${count.index}"
    group = "${var.cluster_prefix}-terraform-created"
  }
}

resource "aws_eip" "nat" {
  vpc        = true
  count      = "${var.az_count}"
  depends_on = ["aws_internet_gateway.public_gateway"]
}

resource "aws_nat_gateway" "private_gateway" {
  count         = "${var.az_count}"
  allocation_id = "${element(aws_eip.nat.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.public.*.id, count.index)}"

  tags {
    Name = "${var.cluster_prefix}"
    group = "${var.cluster_prefix}-terraform-created"
  }
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.cluster_vpc.id}"
  count  = "${var.az_count}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${element(aws_nat_gateway.private_gateway.*.id, count.index)}"
  }

  tags {
    Name = "${var.cluster_prefix}-private"
    group = "${var.cluster_prefix}-terraform-created"
  }
}

resource "aws_route_table_association" "private" {
  count          = "${var.az_count}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}


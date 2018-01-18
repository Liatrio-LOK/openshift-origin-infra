provider "aws" {
  region = "us-east-1"
}

variable aws_key_pair {
  default = "lok-os"
}

variable ami {
  default = "ami-ae7bfdb8" # CentOS 7 us-east-1
}

variable domain {}
variable cluster_prefix {}
variable az_count {}
variable node_count {}

variable github_oauth_client_id {}
variable github_oauth_client_secret {}
variable github_oauth_org {}

terraform {
  backend "s3" {
    bucket = "openshift-origin-tfstates"
    key = "state/os-terraform.tfstate"
    region = "us-east-1"
  }
}

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

data "terraform_remote_state" "network" {
  backend = "s3"
  config {
    bucket = "openshift-origin-tfstates"
    key    = "state/${terraform.workspace}/${var.cluster_prefix}-terraform.tfstate"
    region = "us-east-1"
  }
}

terraform {
  required_version        = ">= 0.12.24"
  required_providers {
    aws                   = ">= 5.14.0"
    external              = ">= 2.3.1"
    local                 = ">= 2.4.0"
  }
}

provider "aws" {
  profile                 = var.aws_profile
  region                  = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

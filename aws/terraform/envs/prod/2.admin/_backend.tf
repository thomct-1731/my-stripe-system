###################
# General Initialization
###################
terraform {
  required_version = ">= 1.3.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    template = "~> 2.0"
  }
  backend "s3" {
    profile = "project-prod"
    bucket  = "project-prod-iac-state"
    key     = "admin/terraform.prod.tfstate"
    region  = "ap-northeast-1"
    /* encrypt        = true
    kms_key_id     = "arn:aws:kms:ap-northeast-1:<account-id>:key/<key-id>" */
    dynamodb_table = "project-prod-terraform-state-lock"
  }
}

# Configure the AWS Provider
provider "aws" {
  region  = var.region
  profile = "${var.project}-${var.env}"
  default_tags {
    tags = {
      Project     = var.project
      Environment = var.env
    }
  }
}
data "aws_caller_identity" "current" {}


###################
# General State
###################
data "terraform_remote_state" "general" {
  backend = "s3"
  config = {
    profile = "${var.project}-${var.env}"
    bucket  = "${var.project}-${var.env}-iac-state"
    key     = "general/terraform.${var.env}.tfstate"
    region  = var.region
  }
}

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
    profile = "project-stg"
    bucket  = "project-stg-iac-state"
    key     = "general/terraform.stg.tfstate"
    region  = "ap-northeast-1"
    /* encrypt        = true
    kms_key_id     = "arn:aws:kms:ap-northeast-1:<account-id>:key/<key-id>" */
    dynamodb_table = "project-stg-terraform-state-lock"
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

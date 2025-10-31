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
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
  backend "s3" {
    profile        = "my-stripe-system-dev"
    bucket         = "my-stripe-system-dev-iac-state"
    key            = "orders/terraform.dev.tfstate"
    region         = "ap-northeast-1"
    /* encrypt        = true
    kms_key_id     = "arn:aws:kms:ap-northeast-1:<account-id>:key/<key-id>" */
    dynamodb_table = "my-stripe-system-dev-terraform-state-lock"
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
      Service     = "order-processing"
    }
  }
}

data "aws_caller_identity" "current" {}

###################
# Remote State References
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

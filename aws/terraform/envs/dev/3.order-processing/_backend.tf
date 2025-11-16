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
    profile        = "myproject-dev"
    bucket         = "myproject-dev-iac-state"
    key            = "3.order-processing/terraform.dev.tfstate"
    region         = "ap-northeast-1"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:ap-northeast-1:<account-id>:key/xxx-xxxx-xxxx"
    dynamodb_table = "myprojectm-dev-terraform-state-lock"
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

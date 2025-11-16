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
    profile        = "myproject-stg"
    bucket         = "myproject-stg-iac-state"
    key            = "3.order-processing/terraform.stg.tfstate"
    region         = "ap-northeast-1"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:ap-northeast-1:<account-id>:key/xxx-xxx-xxxx"
    dynamodb_table = "myproject-stg-terraform-state-lock"
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

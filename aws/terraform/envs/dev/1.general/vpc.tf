###################
# Create VPC and only one Nat Gateway for all AZs
###################
module "vpc" {
  source = "git@github.com:framgia/sun-infra-iac.git//modules/vpc?ref=terraform-aws-vpc_v0.0.1"
  #basic
  env     = var.env
  project = var.project
  region  = var.region

  #vpc
  vpc_cidr      = "10.0.0.0/16"
  public_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
}

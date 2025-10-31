###################
# IAM Role for Lambda example with default policy
###################
module "iam_role_lambda_example" {
  source = "git@github.com:framgia/sun-infra-iac.git//modules/iam-role?ref=terraform-aws-iam_v0.1.2"
  #basic
  env     = var.env
  project = var.project
  service = "lambda"

  #iam-role
  name               = "lambda-example"
  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json
  iam_default_policy_arn = [
    "arn:aws:iam::aws:policy/AdministratorAccess",
    "arn:aws:iam::aws:policy/ReadOnlyAccess"
  ]
}

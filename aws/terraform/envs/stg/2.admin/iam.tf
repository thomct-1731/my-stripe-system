###################
# IAM Role for Lambda example admin with custom policy
###################
module "iam_role_lambda_example_admin" {
  source = "git@github.com:framgia/sun-infra-iac.git//modules/iam-role?ref=terraform-aws-iam_v0.1.2"
  #basic
  env     = var.env
  project = var.project
  service = "lambda"

  #iam-role
  name               = "lambda-example-admin"
  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json
  iam_custom_policy = {
    template = jsonencode(
      {
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Effect" : "Allow",
            "Action" : [
              "logs:CreateLogGroup",
              "logs:CreateLogStream",
              "logs:PutLogEvents"
            ],
            "Resource" : "*"
          },
          {
            "Effect" : "Allow",
            "Action" : [
              "ssm:GetParameter",
              "ssm:GetParameters"
            ],
            "Resource" : "*"
          },
          {
            "Effect" : "Allow",
            "Action" : [
              "kms:Decrypt"
            ],
            "Resource" : "*"
          },
          {
            "Effect" : "Allow",
            "Action" : [
              "iam:PassRole"
            ],
            "Resource" : data.terraform_remote_state.general.outputs.iam_role_lambda_example_arn
          }
        ]
      }
    )
  }
}

output "aws_account_id" {
  value       = <<VALUE

  Check AWS Env:
    Project : "${var.project}" | Env: "${var.env}"
    AWS Account ID: "${data.aws_caller_identity.current.account_id}"
    AWS Account ARN: "${data.aws_caller_identity.current.arn}"
  VALUE
  description = "Show information about project, environment and account"
}

#Output modules
output "iam_role_lambda_example_admin_arn" {
  value       = module.iam_role_lambda_example_admin.iam_role_arn
  description = "ARN of IAM Role Lambda Example Admin"
}

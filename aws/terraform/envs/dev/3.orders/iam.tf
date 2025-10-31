# IAM Role for webhook_validator Lambda
module "iam_role_webhook_validator" {
  source             = "git@github.com:framgia/sun-infra-iac.git//modules/iam-role?ref=terraform-aws-iam_v0.1.2"
  env                = var.env
  project            = var.project
  service            = "lambda"
  name               = "webhook-validator"
  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json
  iam_custom_policy = {
    template = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        { "Effect" : "Allow", "Action" : ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], "Resource" : "arn:aws:logs:*:*:*" },
        { "Effect" : "Allow", "Action" : "sns:Publish", "Resource" : module.sns_topic_orders.topic_arn },
        { "Effect" : "Allow", "Action" : ["secretsmanager:GetSecretValue"], "Resource" : data.aws_secretsmanager_secret.stripe.arn }
      ]
    })
  }
}

# IAM Role for email_processor Lambda
module "iam_role_email_processor" {
  source             = "git@github.com:framgia/sun-infra-iac.git//modules/iam-role?ref=terraform-aws-iam_v0.1.2"
  env                = var.env
  project            = var.project
  service            = "lambda"
  name               = "email-processor"
  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json
  iam_custom_policy = {
    template = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        { "Effect" : "Allow", "Action" : ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], "Resource" : "arn:aws:logs:*:*:*" },
        { "Effect" : "Allow", "Action" : ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"], "Resource" : module.sqs_email_queue.queue_arn },
        { "Effect" : "Allow", "Action" : "ses:SendEmail", "Resource" : "*" } // Nên giới hạn resource ARN của SES identity
      ]
    })
  }
}

# IAM Role for db_update_processor Lambda
module "iam_role_db_update_processor" {
  source             = "git@github.com:framgia/sun-infra-iac.git//modules/iam-role?ref=terraform-aws-iam_v0.1.2"
  env                = var.env
  project            = var.project
  service            = "lambda"
  name               = "db-update-processor"
  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json
  iam_custom_policy = {
    template = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        { "Effect" : "Allow", "Action" : ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], "Resource" : "arn:aws:logs:*:*:*" },
        { "Effect" : "Allow", "Action" : ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"], "Resource" : module.sqs_db_update_queue.queue_arn },
        { "Effect" : "Allow", "Action" : ["dynamodb:PutItem", "dynamodb:UpdateItem"], "Resource" : aws_dynamodb_table.orders.arn }
      ]
    })
  }
}

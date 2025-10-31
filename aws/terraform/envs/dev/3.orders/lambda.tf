# --- Lambda Modules ---
# Giả định bạn có một module chung để tạo Lambda và đóng gói code
module "lambda_webhook_validator" {
  source        = "git@github.com:framgia/sun-infra-iac.git//modules/lambda?ref=..." # Thay bằng ref/version module lambda của bạn
  function_name = "${var.project}-${var.env}-webhook-validator"
  handler       = "webhook_validator.handler"
  runtime       = "python3.9"
  role_arn      = module.iam_role_webhook_validator.iam_role_arn
  source_path   = "${var.lambda_source_path}/webhook_validator"
  environment_variables = {
    SNS_TOPIC_ARN = module.sns_topic_orders.topic_arn
    STRIPE_SECRET_NAME = data.aws_secretsmanager_secret.stripe.name
  }
}

module "lambda_email_processor" {
  source        = "git@github.com:framgia/sun-infra-iac.git//modules/lambda?ref=..." # Thay bằng ref/version module lambda của bạn
  function_name = "${var.project}-${var.env}-email-processor"
  handler       = "email_processor.handler"
  runtime       = "python3.9"
  role_arn      = module.iam_role_email_processor.iam_role_arn
  source_path   = "${var.lambda_source_path}/email_processor"
  environment_variables = {
    SES_SENDER_EMAIL = "no-reply@yourdomain.com" // Cần xác thực email này trong SES
  }
}

module "lambda_db_update_processor" {
  source        = "git@github.com:framgia/sun-infra-iac.git//modules/lambda?ref=..." # Thay bằng ref/version module lambda của bạn
  function_name = "${var.project}-${var.env}-db-update-processor"
  handler       = "db_update_processor.handler"
  runtime       = "python3.9"
  role_arn      = module.iam_role_db_update_processor.iam_role_arn
  source_path   = "${var.lambda_source_path}/db_update_processor"
  environment_variables = {
    ORDERS_TABLE_NAME = aws_dynamodb_table.orders.name
  }
}

# --- Event Source Mappings ---
resource "aws_lambda_event_source_mapping" "email_mapping" {
  event_source_arn = module.sqs_email_queue.queue_arn
  function_name    = module.lambda_email_processor.function_arn
  batch_size       = 5
}

resource "aws_lambda_event_source_mapping" "db_update_mapping" {
  event_source_arn = module.sqs_db_update_queue.queue_arn
  function_name    = module.lambda_db_update_processor.function_arn
  batch_size       = 5
}

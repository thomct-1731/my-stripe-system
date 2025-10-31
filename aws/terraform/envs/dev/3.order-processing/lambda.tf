###################
# Lambda Function Source Code Archives
###################
data "archive_file" "webhook_handler" {
  type        = "zip"
  source_file = "${path.module}/webhook_handler.zip"
  output_path = "${path.module}/webhook_handler_deployment.zip"

  depends_on = []
}

data "archive_file" "email_processor" {
  type        = "zip"
  source_file = "${path.module}/email_processor.zip"
  output_path = "${path.module}/email_processor_deployment.zip"

  depends_on = []
}

data "archive_file" "inventory_processor" {
  type        = "zip"
  source_file = "${path.module}/inventory_processor.zip"
  output_path = "${path.module}/inventory_processor_deployment.zip"

  depends_on = []
}

data "archive_file" "database_processor" {
  type        = "zip"
  source_file = "${path.module}/database_processor.zip"
  output_path = "${path.module}/database_processor_deployment.zip"

  depends_on = []
}

###################
# Webhook Handler Lambda
###################
resource "aws_lambda_function" "webhook_handler" {
  filename         = data.archive_file.webhook_handler.output_path
  function_name    = "${var.project}-${var.env}-webhook-handler"
  role            = aws_iam_role.webhook_handler_role.arn
  handler         = "main.handler"
  runtime         = "python3.9"
  timeout         = 30
  source_code_hash = data.archive_file.webhook_handler.output_base64sha256

  environment {
    variables = {
      SNS_TOPIC_ARN              = aws_sns_topic.order_events.arn
      STRIPE_WEBHOOK_SECRET      = aws_secretsmanager_secret.stripe_webhook_secret.name
      ORDERS_TABLE              = aws_dynamodb_table.orders.name
      PROCESSING_LOGS_TABLE     = aws_dynamodb_table.processing_logs.name
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.webhook_handler_basic,
    aws_cloudwatch_log_group.webhook_handler,
  ]

  tags = {
    Name = "${var.project}-${var.env}-webhook-handler"
  }
}

###################
# Email Processor Lambda
###################
resource "aws_lambda_function" "email_processor" {
  filename         = data.archive_file.email_processor.output_path
  function_name    = "${var.project}-${var.env}-email-processor"
  role            = aws_iam_role.email_processor_role.arn
  handler         = "main.handler"
  runtime         = "python3.9"
  timeout         = 60
  source_code_hash = data.archive_file.email_processor.output_base64sha256

  environment {
    variables = {
      PROCESSING_LOGS_TABLE = aws_dynamodb_table.processing_logs.name
      FROM_EMAIL           = "noreply@yourdomain.com"  # Update this
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.email_processor_basic,
    aws_cloudwatch_log_group.email_processor,
  ]

  tags = {
    Name = "${var.project}-${var.env}-email-processor"
  }
}

###################
# Inventory Processor Lambda
###################
resource "aws_lambda_function" "inventory_processor" {
  filename         = data.archive_file.inventory_processor.output_path
  function_name    = "${var.project}-${var.env}-inventory-processor"
  role            = aws_iam_role.inventory_processor_role.arn
  handler         = "main.handler"
  runtime         = "python3.9"
  timeout         = 60
  source_code_hash = data.archive_file.inventory_processor.output_base64sha256

  environment {
    variables = {
      ORDERS_TABLE          = aws_dynamodb_table.orders.name
      PROCESSING_LOGS_TABLE = aws_dynamodb_table.processing_logs.name
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.inventory_processor_basic,
    aws_cloudwatch_log_group.inventory_processor,
  ]

  tags = {
    Name = "${var.project}-${var.env}-inventory-processor"
  }
}

###################
# Database Processor Lambda
###################
resource "aws_lambda_function" "database_processor" {
  filename         = data.archive_file.database_processor.output_path
  function_name    = "${var.project}-${var.env}-database-processor"
  role            = aws_iam_role.database_processor_role.arn
  handler         = "main.handler"
  runtime         = "python3.9"
  timeout         = 120
  source_code_hash = data.archive_file.database_processor.output_base64sha256

  environment {
    variables = {
      ORDERS_TABLE          = aws_dynamodb_table.orders.name
      PROCESSING_LOGS_TABLE = aws_dynamodb_table.processing_logs.name
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.database_processor_basic,
    aws_cloudwatch_log_group.database_processor,
  ]

  tags = {
    Name = "${var.project}-${var.env}-database-processor"
  }
}

###################
# Lambda Event Source Mappings
###################
resource "aws_lambda_event_source_mapping" "email_processor_trigger" {
  event_source_arn = aws_sqs_queue.email_queue.arn
  function_name    = aws_lambda_function.email_processor.arn
  batch_size       = 10
  maximum_batching_window_in_seconds = 5

  depends_on = [aws_iam_role_policy_attachment.email_processor_sqs]
}

resource "aws_lambda_event_source_mapping" "inventory_processor_trigger" {
  event_source_arn = aws_sqs_queue.inventory_queue.arn
  function_name    = aws_lambda_function.inventory_processor.arn
  batch_size       = 10
  maximum_batching_window_in_seconds = 5

  depends_on = [aws_iam_role_policy_attachment.inventory_processor_sqs]
}

resource "aws_lambda_event_source_mapping" "database_processor_trigger" {
  event_source_arn = aws_sqs_queue.database_queue.arn
  function_name    = aws_lambda_function.database_processor.arn
  batch_size       = 5
  maximum_batching_window_in_seconds = 10

  depends_on = [aws_iam_role_policy_attachment.database_processor_sqs]
}

###################
# CloudWatch Log Groups
###################
resource "aws_cloudwatch_log_group" "webhook_handler" {
  name              = "/aws/lambda/${var.project}-${var.env}-webhook-handler"
  retention_in_days = 14

  tags = {
    Name = "${var.project}-${var.env}-webhook-handler-logs"
  }
}

resource "aws_cloudwatch_log_group" "email_processor" {
  name              = "/aws/lambda/${var.project}-${var.env}-email-processor"
  retention_in_days = 14

  tags = {
    Name = "${var.project}-${var.env}-email-processor-logs"
  }
}

resource "aws_cloudwatch_log_group" "inventory_processor" {
  name              = "/aws/lambda/${var.project}-${var.env}-inventory-processor"
  retention_in_days = 14

  tags = {
    Name = "${var.project}-${var.env}-inventory-processor-logs"
  }
}

resource "aws_cloudwatch_log_group" "database_processor" {
  name              = "/aws/lambda/${var.project}-${var.env}-database-processor"
  retention_in_days = 14

  tags = {
    Name = "${var.project}-${var.env}-database-processor-logs"
  }
}

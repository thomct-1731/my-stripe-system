# Terraform Outputs for API Gateway and Resources
output "webhook_endpoint_url" {
  description = "API Gateway webhook endpoint URL for Stripe"
  value       = "${aws_apigatewayv2_api.webhook_api.api_endpoint}/webhook"
}

output "api_gateway_id" {
  description = "ID of API Gateway"
  value       = aws_apigatewayv2_api.webhook_api.id
}

output "api_gateway_arn" {
  description = "ARN of API Gateway"
  value       = aws_apigatewayv2_api.webhook_api.arn
}

output "sns_topic_arn" {
  description = "ARN of SNS topic for order events"
  value       = aws_sns_topic.order_events.arn
}

output "dynamodb_table_name" {
  description = "Name of DynamoDB orders table"
  value       = aws_dynamodb_table.orders.name
}

output "dynamodb_table_arn" {
  description = "ARN of DynamoDB orders table"
  value       = aws_dynamodb_table.orders.arn
}

output "processing_logs_table_name" {
  description = "Name of DynamoDB processing logs table"
  value       = aws_dynamodb_table.processing_logs.name
}

output "email_queue_url" {
  description = "URL of SQS email queue"
  value       = aws_sqs_queue.email_queue.url
}

output "inventory_queue_url" {
  description = "URL of SQS inventory queue"
  value       = aws_sqs_queue.inventory_queue.url
}

output "database_queue_url" {
  description = "URL of SQS database queue"
  value       = aws_sqs_queue.database_queue.url
}

output "webhook_handler_function_name" {
  description = "Name of webhook handler Lambda function"
  value       = aws_lambda_function.webhook_handler.function_name
}

output "webhook_handler_function_arn" {
  description = "ARN of webhook handler Lambda function"
  value       = aws_lambda_function.webhook_handler.arn
}

output "email_processor_function_name" {
  description = "Name of email processor Lambda function"
  value       = aws_lambda_function.email_processor.function_name
}

output "inventory_processor_function_name" {
  description = "Name of inventory processor Lambda function"
  value       = aws_lambda_function.inventory_processor.function_name
}

output "database_processor_function_name" {
  description = "Name of database processor Lambda function"
  value       = aws_lambda_function.database_processor.function_name
}

output "cloudwatch_dashboard_url" {
  description = "URL to CloudWatch dashboard for order processing"
  value       = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.order_processing.dashboard_name}"
}

output "cloudwatch_log_groups" {
  description = "CloudWatch log groups for Lambda functions"
  value = {
    webhook_handler      = aws_cloudwatch_log_group.webhook_handler.name
    email_processor      = aws_cloudwatch_log_group.email_processor.name
    inventory_processor  = aws_cloudwatch_log_group.inventory_processor.name
    database_processor   = aws_cloudwatch_log_group.database_processor.name
  }
}

output "stripe_webhook_secret_arn" {
  description = "ARN of Stripe webhook secret in Secrets Manager"
  value       = aws_secretsmanager_secret.stripe_webhook_secret.arn
  sensitive   = true
}

output "email_config_secret_arn" {
  description = "ARN of email config secret in Secrets Manager"
  value       = aws_secretsmanager_secret.email_config.arn
  sensitive   = true
}

output "dlq_arns" {
  description = "ARNs of Dead Letter Queues"
  value = {
    email_dlq     = aws_sqs_queue.email_dlq.arn
    inventory_dlq = aws_sqs_queue.inventory_dlq.arn
    database_dlq  = aws_sqs_queue.database_dlq.arn
  }
}

output "alarm_topic_arn" {
  description = "ARN of SNS topic for CloudWatch alarms"
  value       = aws_sns_topic.alerts.arn
}

# Summary output for quick reference
output "deployment_summary" {
  description = "Summary of deployed resources"
  value = <<-EOT
    ======================================
    Stripe Order Processing System - Deployment Summary
    ======================================

    Environment: ${var.env}
    Region: ${var.region}

    1. Webhook Endpoint:
      ${aws_apigatewayv2_api.webhook_api.api_endpoint}/webhook

    2. Monitoring Dashboard:
      https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.order_processing.dashboard_name}

    3. Secrets Manager:
      - Stripe Webhook: ${aws_secretsmanager_secret.stripe_webhook_secret.name}
      - Email Config: ${aws_secretsmanager_secret.email_config.name}

    4. Lambda Functions:
      - Webhook Handler: ${aws_lambda_function.webhook_handler.function_name}
      - Email Processor: ${aws_lambda_function.email_processor.function_name}
      - Inventory Processor: ${aws_lambda_function.inventory_processor.function_name}
      - Database Processor: ${aws_lambda_function.database_processor.function_name}

    5. SQS Queues:
      - Email Queue: ${aws_sqs_queue.email_queue.name}
      - Inventory Queue: ${aws_sqs_queue.inventory_queue.name}
      - Database Queue: ${aws_sqs_queue.database_queue.name}

    6. DynamoDB Tables:
      - Orders: ${aws_dynamodb_table.orders.name}
      - Processing Logs: ${aws_dynamodb_table.processing_logs.name}

    7. Next Steps:
      7.1. Configure Stripe webhook with the endpoint URL above
      7.2. Update secrets in AWS Secrets Manager
      7.3. Verify SES email identity
      7.4. Test webhook with Stripe CLI: stripe trigger checkout.session.completed

    ======================================
  EOT
}

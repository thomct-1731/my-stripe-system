output "api_gateway_invoke_url" {
  description = "The invoke URL for the Orders API Gateway"
  value       = aws_apigatewayv2_api.orders_api.api_endpoint
}

output "orders_sns_topic_arn" {
  description = "ARN of the orders SNS topic"
  value       = module.sns_topic_orders.topic_arn
}

output "orders_dynamodb_table_name" {
  description = "Name of the orders DynamoDB table"
  value       = aws_dynamodb_table.orders.name
}

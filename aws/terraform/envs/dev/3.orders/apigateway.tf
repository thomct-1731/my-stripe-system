resource "aws_apigatewayv2_api" "orders_api" {
  name          = "${var.project}-${var.env}-orders-api"
  protocol_type = "HTTP"
  description   = "API for Stripe Webhooks"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.orders_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "webhook_validator" {
  api_id           = aws_apigatewayv2_api.orders_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = module.lambda_webhook_validator.function_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "webhook_post" {
  api_id    = aws_apigatewayv2_api.orders_api.id
  route_key = "POST /webhook"
  target    = "integrations/${aws_apigatewayv2_integration.webhook_validator.id}"
}

resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_webhook_validator.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.orders_api.execution_arn}/*/*"
}

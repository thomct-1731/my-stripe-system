###################
# API Gateway for Stripe Webhooks
###################
resource "aws_api_gateway_rest_api" "webhook_api" {
  name        = "${var.project}-${var.env}-webhook-api"
  description = "API Gateway for Stripe webhook processing"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name = "${var.project}-${var.env}-webhook-api"
  }
}

resource "aws_api_gateway_resource" "webhook_resource" {
  rest_api_id = aws_api_gateway_rest_api.webhook_api.id
  parent_id   = aws_api_gateway_rest_api.webhook_api.root_resource_id
  path_part   = "webhook"
}

resource "aws_api_gateway_method" "webhook_post" {
  rest_api_id   = aws_api_gateway_rest_api.webhook_api.id
  resource_id   = aws_api_gateway_resource.webhook_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "webhook_integration" {
  rest_api_id = aws_api_gateway_rest_api.webhook_api.id
  resource_id = aws_api_gateway_resource.webhook_resource.id
  http_method = aws_api_gateway_method.webhook_post.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.webhook_handler.invoke_arn
}

resource "aws_api_gateway_deployment" "webhook_deployment" {
  depends_on = [
    aws_api_gateway_integration.webhook_integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.webhook_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.webhook_resource.id,
      aws_api_gateway_method.webhook_post.id,
      aws_api_gateway_integration.webhook_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "webhook_stage" {
  deployment_id = aws_api_gateway_deployment.webhook_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.webhook_api.id
  stage_name    = var.env

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = {
    Name = "${var.project}-${var.env}-webhook-stage"
  }
}

resource "aws_lambda_permission" "api_gateway_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.webhook_handler.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.webhook_api.execution_arn}/*/*"
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.project}-${var.env}-webhook-api"
  retention_in_days = 14

  tags = {
    Name = "${var.project}-${var.env}-api-gateway-logs"
  }
}

# module "sns_topic_orders" {
#   source  = "git@github.com:framgia/sun-infra-iac.git//modules/sns?ref=..." # ref/version module sns
#   name    = "${var.project}-${var.env}-orders"
#   project = var.project
#   env     = var.env
# }


###################
# SNS Topic for Order Events
###################
resource "aws_sns_topic" "order_events" {
  name              = "${var.project}-${var.env}-order-events"
  kms_master_key_id = "alias/aws/sns"

  tags = {
    Name = "${var.project}-${var.env}-order-events"
  }
}

resource "aws_sns_topic_policy" "order_events" {
  arn = aws_sns_topic.order_events.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "OrderEventsTopicPolicy"
    Statement = [
      {
        Sid    = "AllowLambdaPublish"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.webhook_handler_role.arn
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.order_events.arn
      }
    ]
  })
}

###################
# SNS Subscriptions to SQS Queues
###################
resource "aws_sns_topic_subscription" "email_queue_subscription" {
  topic_arn = aws_sns_topic.order_events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.email_queue.arn

  filter_policy = jsonencode({
    event_type = ["order_completed", "order_failed"]
  })
}

resource "aws_sns_topic_subscription" "inventory_queue_subscription" {
  topic_arn = aws_sns_topic.order_events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.inventory_queue.arn

  filter_policy = jsonencode({
    event_type = ["order_completed"]
  })
}

resource "aws_sns_topic_subscription" "database_queue_subscription" {
  topic_arn = aws_sns_topic.order_events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.database_queue.arn

  filter_policy = jsonencode({
    event_type = ["order_completed", "order_failed", "order_processing"]
  })
}

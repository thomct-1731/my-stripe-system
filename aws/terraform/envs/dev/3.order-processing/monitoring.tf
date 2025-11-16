###################
# CloudWatch Alarms for SQS Queue Monitoring
###################
resource "aws_cloudwatch_metric_alarm" "email_queue_messages" {
  alarm_name          = "${var.project}-${var.env}-email-queue-messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApproximateNumberOfVisibleMessages"
  namespace           = "AWS/SQS"
  period              = "300"
  statistic           = "Average"
  threshold           = "100"
  alarm_description   = "This metric monitors email queue message count"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    QueueName = aws_sqs_queue.email_queue.name
  }

  tags = {
    Name = "${var.project}-${var.env}-email-queue-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "inventory_queue_messages" {
  alarm_name          = "${var.project}-${var.env}-inventory-queue-messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApproximateNumberOfVisibleMessages"
  namespace           = "AWS/SQS"
  period              = "300"
  statistic           = "Average"
  threshold           = "50"
  alarm_description   = "This metric monitors inventory queue message count"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    QueueName = aws_sqs_queue.inventory_queue.name
  }

  tags = {
    Name = "${var.project}-${var.env}-inventory-queue-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "database_queue_messages" {
  alarm_name          = "${var.project}-${var.env}-database-queue-messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApproximateNumberOfVisibleMessages"
  namespace           = "AWS/SQS"
  period              = "300"
  statistic           = "Average"
  threshold           = "200"
  alarm_description   = "This metric monitors database queue message count"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    QueueName = aws_sqs_queue.database_queue.name
  }

  tags = {
    Name = "${var.project}-${var.env}-database-queue-alarm"
  }
}

###################
# Dead Letter Queue Alarms
###################
resource "aws_cloudwatch_metric_alarm" "email_dlq_messages" {
  alarm_name          = "${var.project}-${var.env}-email-dlq-messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ApproximateNumberOfVisibleMessages"
  namespace           = "AWS/SQS"
  period              = "60"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "This metric monitors email DLQ for failed messages"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    QueueName = aws_sqs_queue.email_dlq.name
  }

  tags = {
    Name = "${var.project}-${var.env}-email-dlq-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "inventory_dlq_messages" {
  alarm_name          = "${var.project}-${var.env}-inventory-dlq-messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ApproximateNumberOfVisibleMessages"
  namespace           = "AWS/SQS"
  period              = "60"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "This metric monitors inventory DLQ for failed messages"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    QueueName = aws_sqs_queue.inventory_dlq.name
  }

  tags = {
    Name = "${var.project}-${var.env}-inventory-dlq-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "database_dlq_messages" {
  alarm_name          = "${var.project}-${var.env}-database-dlq-messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ApproximateNumberOfVisibleMessages"
  namespace           = "AWS/SQS"
  period              = "60"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "This metric monitors database DLQ for failed messages"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    QueueName = aws_sqs_queue.database_dlq.name
  }

  tags = {
    Name = "${var.project}-${var.env}-database-dlq-alarm"
  }
}

###################
# Lambda Function Error Alarms
###################
resource "aws_cloudwatch_metric_alarm" "webhook_handler_errors" {
  alarm_name          = "${var.project}-${var.env}-webhook-handler-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors webhook handler lambda errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = aws_lambda_function.webhook_handler.function_name
  }

  tags = {
    Name = "${var.project}-${var.env}-webhook-handler-errors-alarm"
  }
}

###################
# SNS Topic for Alerts
###################
resource "aws_sns_topic" "alerts" {
  name = "${var.project}-${var.env}-alerts"

  tags = {
    Name = "${var.project}-${var.env}-alerts"
  }
}

resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "chuthom97@gmail.com"
}

###################
# CloudWatch Dashboard
###################
resource "aws_cloudwatch_dashboard" "order_processing" {
  dashboard_name = "${var.project}-${var.env}-order-processing"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfVisibleMessages", "QueueName", aws_sqs_queue.email_queue.name],
            [".", ".", ".", aws_sqs_queue.inventory_queue.name],
            [".", ".", ".", aws_sqs_queue.database_queue.name]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "SQS Queue Messages"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", aws_lambda_function.webhook_handler.function_name],
            [".", ".", ".", aws_lambda_function.email_processor.function_name],
            [".", ".", ".", aws_lambda_function.inventory_processor.function_name],
            [".", ".", ".", aws_lambda_function.database_processor.function_name]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "Lambda Function Duration"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.webhook_handler.function_name],
            [".", ".", ".", aws_lambda_function.email_processor.function_name],
            [".", ".", ".", aws_lambda_function.inventory_processor.function_name],
            [".", ".", ".", aws_lambda_function.database_processor.function_name]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "Lambda Function Errors"
          period  = 300
        }
      }
    ]
  })
}

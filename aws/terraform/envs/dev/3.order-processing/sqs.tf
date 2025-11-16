###################
# Dead Letter Queues
###################
resource "aws_sqs_queue" "email_dlq" {
  name                      = "${var.project}-${var.env}-email-dlq"
  message_retention_seconds = 1209600 # 14 days

  tags = {
    Name = "${var.project}-${var.env}-email-dlq"
    Type = "DeadLetterQueue"
  }
}

resource "aws_sqs_queue" "inventory_dlq" {
  name                      = "${var.project}-${var.env}-inventory-dlq"
  message_retention_seconds = 1209600 # 14 days

  tags = {
    Name = "${var.project}-${var.env}-inventory-dlq"
    Type = "DeadLetterQueue"
  }
}

resource "aws_sqs_queue" "database_dlq" {
  name                      = "${var.project}-${var.env}-database-dlq"
  message_retention_seconds = 1209600 # 14 days

  tags = {
    Name = "${var.project}-${var.env}-database-dlq"
    Type = "DeadLetterQueue"
  }
}

###################
# Main Processing Queues
###################
resource "aws_sqs_queue" "email_queue" {
  name                       = "${var.project}-${var.env}-email-queue"
  delay_seconds              = 0
  max_message_size           = 262144
  message_retention_seconds  = 345600 # 4 days
  receive_wait_time_seconds  = 10
  visibility_timeout_seconds = 60

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.email_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name = "${var.project}-${var.env}-email-queue"
  }
}

resource "aws_sqs_queue" "inventory_queue" {
  name                       = "${var.project}-${var.env}-inventory-queue"
  delay_seconds              = 0
  max_message_size           = 262144
  message_retention_seconds  = 345600 # 4 days
  receive_wait_time_seconds  = 10
  visibility_timeout_seconds = 60

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.inventory_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name = "${var.project}-${var.env}-inventory-queue"
  }
}

resource "aws_sqs_queue" "database_queue" {
  name                       = "${var.project}-${var.env}-database-queue"
  delay_seconds              = 0
  max_message_size           = 262144
  message_retention_seconds  = 345600 # 4 days
  receive_wait_time_seconds  = 10
  visibility_timeout_seconds = 120

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.database_dlq.arn
    maxReceiveCount     = 5
  })

  tags = {
    Name = "${var.project}-${var.env}-database-queue"
  }
}

###################
# SQS Queue Policies for SNS
###################
resource "aws_sqs_queue_policy" "email_queue_policy" {
  queue_url = aws_sqs_queue.email_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "EmailQueuePolicy"
    Statement = [
      {
        Sid       = "AllowSNSPublish"
        Effect    = "Allow"
        Principal = "*"
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.email_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.order_events.arn
          }
        }
      }
    ]
  })
}

resource "aws_sqs_queue_policy" "inventory_queue_policy" {
  queue_url = aws_sqs_queue.inventory_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "InventoryQueuePolicy"
    Statement = [
      {
        Sid       = "AllowSNSPublish"
        Effect    = "Allow"
        Principal = "*"
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.inventory_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.order_events.arn
          }
        }
      }
    ]
  })
}

resource "aws_sqs_queue_policy" "database_queue_policy" {
  queue_url = aws_sqs_queue.database_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "DatabaseQueuePolicy"
    Statement = [
      {
        Sid       = "AllowSNSPublish"
        Effect    = "Allow"
        Principal = "*"
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.database_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.order_events.arn
          }
        }
      }
    ]
  })
}

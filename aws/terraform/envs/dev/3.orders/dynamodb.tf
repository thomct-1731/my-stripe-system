###################
# DynamoDB Table for Orders
###################
resource "aws_dynamodb_table" "orders" {
  name         = "${var.project}-${var.env}-orders"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "order_id"
  stream_enabled = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "order_id"
    type = "S"
  }

  attribute {
    name = "customer_email"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  global_secondary_index {
    name            = "CustomerEmailIndex"
    hash_key        = "customer_email"
    projection_type = "ALL"
    range_key = "created_at"
  }

  global_secondary_index {
    name     = "StatusIndex"
    hash_key = "status"
    projection_type = "ALL"
    range_key = "created_at"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name = "${var.project}-${var.env}-orders"
  }
}

###################
# DynamoDB Table for Order Processing Logs
###################
resource "aws_dynamodb_table" "processing_logs" {
  name           = "${var.project}-${var.env}-processing-logs"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "log_id"
  range_key      = "timestamp"

  attribute {
    name = "log_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  attribute {
    name = "order_id"
    type = "S"
  }

  global_secondary_index {
    name     = "OrderIdIndex"
    hash_key = "order_id"
    projection_type = "ALL"
    range_key = "timestamp"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = {
    Name = "${var.project}-${var.env}-processing-logs"
  }
}

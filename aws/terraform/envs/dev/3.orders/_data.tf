data "aws_iam_policy_document" "assume_role_lambda" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_secretsmanager_secret" "stripe" {
  name = "${var.project}/${var.env}/stripe"
}

data "aws_secretsmanager_secret_version" "stripe" {
  secret_id = data.aws_secretsmanager_secret.stripe.id
}

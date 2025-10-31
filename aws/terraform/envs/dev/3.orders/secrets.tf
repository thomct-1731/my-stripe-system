###################
# Secrets Manager for API Keys and Configurations
###################
resource "aws_secretsmanager_secret" "stripe_webhook_secret" {
  name                    = "${var.project}-${var.env}-stripe-webhook-secret"
  description             = "Stripe webhook endpoint secret"
  recovery_window_in_days = 7

  tags = {
    Name = "${var.project}-${var.env}-stripe-webhook-secret"
  }
}

resource "aws_secretsmanager_secret_version" "stripe_webhook_secret" {
  secret_id = aws_secretsmanager_secret.stripe_webhook_secret.id
  secret_string = jsonencode({
    webhook_secret = "whsec_your_stripe_webhook_secret_here"
    api_key        = "sk_test_your_stripe_api_key_here"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "email_config" {
  name                    = "${var.project}-${var.env}-email-config"
  description             = "Email service configuration"
  recovery_window_in_days = 7

  tags = {
    Name = "${var.project}-${var.env}-email-config"
  }
}

resource "aws_secretsmanager_secret_version" "email_config" {
  secret_id = aws_secretsmanager_secret.email_config.id
  secret_string = jsonencode({
    from_email    = "noreply@ctt.com"
    support_email = "support@ctt.com"
    template_path = "email-templates/"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

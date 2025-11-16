resource "aws_ses_domain_identity" "main" {
  domain = "myproject.com"
}

resource "aws_ses_email_identity" "sender" {
  email = "no-reply@myproject.com"
}

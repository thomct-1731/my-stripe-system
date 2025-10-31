resource "aws_ses_domain_identity" "main" {
  domain = "yourdomain.com" # Thay bằng domain của bạn
}

resource "aws_ses_email_identity" "sender" {
  email = "no-reply@yourdomain.com" # Thay bằng email người gửi
}

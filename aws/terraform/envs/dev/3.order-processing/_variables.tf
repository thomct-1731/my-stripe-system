variable "project" {
  description = "Name of project"
  type        = string
  default     = "my-stripe-system"
}

variable "env" {
  description = "Name of project environment"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "Region of environment"
  type        = string
}

variable "lambda_source_path" {
  description = "Path to the lambda function source code directory"
  type        = string
  default     = "../../../terraform-dependencies/lambda-functions/orders"
}

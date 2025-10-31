variable "project" {
  description = "Name of project"
  type        = string
  default     = "my-stripe-system"
}

variable "env" {
  description = "Environment (dev/stg/prod)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

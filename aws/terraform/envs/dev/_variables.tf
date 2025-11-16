variable "project" {
  description = "Name of project"
  type        = string
  default     = "myproject"
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

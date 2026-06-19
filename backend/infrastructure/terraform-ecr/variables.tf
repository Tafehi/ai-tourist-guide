variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "environment" {
  type    = string
  default = "development"

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}

variable "repository_name" {
  type        = string
  default     = "ai-suggestion-app"
  description = "Name of the ECR repository for the Lambda container image"
}

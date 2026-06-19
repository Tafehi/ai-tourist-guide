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

variable "ecr_repository_name" {
  type        = string
  default     = "ai-suggestion-app"
  description = "Name of the ECR repository for the Lambda container image"
}

variable "lambda_function_name" {
  type        = string
  default     = "ai-suggestion-app"
  description = "Name of the Lambda function"
}

variable "lambda_memory_size" {
  type    = number
  default = 512
}

variable "lambda_timeout" {
  type    = number
  default = 60
}

variable "image_tag" {
  type        = string
  default     = "latest"
  description = "Docker image tag for the Lambda container"
}

variable "permissions_boundary" {
  type        = string
  default     = "core/oidc-tooling-github-permissionboundarypolicy"
  description = "Permissions boundary policy name for IAM roles"
}

variable "google_maps_secret_name" {
  type        = string
  default     = ""
  description = "Secrets Manager secret name for Google Maps API key"
}

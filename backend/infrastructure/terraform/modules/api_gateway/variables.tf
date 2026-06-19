variable "environment" {
  type = string
}

variable "lambda_function_name" {
  type = string
}

variable "lambda_invoke_arn" {
  type = string
}

variable "domain_name" {
  type        = string
  default     = ""
  description = "Custom domain name for API Gateway (leave empty to skip)"
}

variable "certificate_arn" {
  type        = string
  default     = ""
  description = "ACM certificate ARN for TLS on the custom domain"
}

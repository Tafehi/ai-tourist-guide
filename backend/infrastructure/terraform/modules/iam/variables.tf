variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "permissions_boundary" {
  type        = string
  description = "Name of the IAM permissions boundary policy"
}

variable "dynamodb_table_arns" {
  type        = list(string)
  description = "List of DynamoDB table ARNs the Lambda needs access to"
}

variable "secrets_arns" {
  type        = list(string)
  default     = []
  description = "List of Secrets Manager secret ARNs the Lambda needs access to"
}

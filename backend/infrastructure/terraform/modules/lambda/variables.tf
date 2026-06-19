variable "function_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "role_arn" {
  type = string
}

variable "image_uri" {
  type = string
}

variable "memory_size" {
  type    = number
  default = 512
}

variable "timeout" {
  type    = number
  default = 60
}

variable "dynamodb_table_itineraries" {
  type = string
}

variable "dynamodb_table_credits" {
  type = string
}

variable "api_key_secret_name" {
  type        = string
  description = "Secrets Manager secret name for the API key"
}

variable "google_maps_secret_name" {
  type        = string
  default     = ""
  description = "Secrets Manager secret name for Google Maps API key"
}

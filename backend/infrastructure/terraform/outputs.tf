output "api_url" {
  value       = module.api_gateway.api_endpoint
  description = "API Gateway endpoint URL"
}

output "ecr_repository_url" {
  value       = data.aws_ecr_repository.this.repository_url
  description = "ECR repository URL for pushing Docker images"
}

output "lambda_function_name" {
  value       = module.lambda.function_name
  description = "Lambda function name"
}

output "dynamodb_tables" {
  value = {
    itineraries = module.dynamodb.itineraries_table_name
    credits     = module.dynamodb.credits_table_name
  }
  description = "DynamoDB table names"
}

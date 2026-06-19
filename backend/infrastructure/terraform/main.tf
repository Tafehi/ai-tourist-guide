# --- Data Sources ---

data "aws_ecr_repository" "this" {
  name = "${var.ecr_repository_name}-${var.environment}"
}

data "aws_caller_identity" "current" {}

# --- Modules ---

module "dynamodb" {
  source = "./modules/dynamodb"
}

module "iam" {
  source = "./modules/iam"

  environment          = var.environment
  aws_region           = var.aws_region
  permissions_boundary = var.permissions_boundary
  dynamodb_table_arns = [
    module.dynamodb.itineraries_table_arn,
    module.dynamodb.credits_table_arn,
  ]
  secrets_arns = [aws_secretsmanager_secret.api_key.arn]
}

# --- Secrets ---

resource "random_password" "api_key" {
  length  = 32
  special = false

  lifecycle {
    ignore_changes = [length, special]
  }
}

resource "aws_secretsmanager_secret" "api_key" {
  name        = "tripcraft-ai-${var.environment}-api-key"
  description = "API key for tripcraft-ai request authentication"
}

resource "aws_secretsmanager_secret_version" "api_key" {
  secret_id     = aws_secretsmanager_secret.api_key.id
  secret_string = random_password.api_key.result

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# --- API Gateway ---

module "api_gateway" {
  source = "./modules/api_gateway"

  environment          = var.environment
  lambda_function_name = module.lambda.function_name
  lambda_invoke_arn    = module.lambda.invoke_arn
}

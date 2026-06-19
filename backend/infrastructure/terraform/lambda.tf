# --- App Lambda (API handler) ---

module "lambda" {
  source = "./modules/lambda"

  function_name              = var.lambda_function_name
  environment                = var.environment
  aws_region                 = var.aws_region
  role_arn                   = module.iam.lambda_role_arn
  image_uri                  = "${data.aws_ecr_repository.this.repository_url}:${var.image_tag}"
  memory_size                = var.lambda_memory_size
  timeout                    = var.lambda_timeout
  dynamodb_table_itineraries = module.dynamodb.itineraries_table_name
  dynamodb_table_credits     = module.dynamodb.credits_table_name
  api_key_secret_name        = aws_secretsmanager_secret.api_key.name
  google_maps_secret_name    = var.google_maps_secret_name
}

# --- Secret Rotation Lambda ---

data "archive_file" "rotation_lambda" {
  type        = "zip"
  source_file = "${path.module}/rotation/rotate.py"
  output_path = "${path.module}/rotation/rotate.zip"
}

resource "aws_iam_role" "rotation_lambda" {
  name                 = "ai-suggestion-app-secret-rotation-${var.environment}"
  path                 = "/service-role/"
  permissions_boundary = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.permissions_boundary}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "rotation_lambda" {
  name = "secrets-manager-rotation"
  role = aws_iam_role.rotation_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetSecretValue",
        "secretsmanager:PutSecretValue",
        "secretsmanager:UpdateSecretVersionStage",
      ]
      Resource = aws_secretsmanager_secret.api_key.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rotation_lambda_basic" {
  role       = aws_iam_role.rotation_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "rotation" {
  function_name    = "ai-suggestion-app-secret-rotation-${var.environment}"
  role             = aws_iam_role.rotation_lambda.arn
  handler          = "rotate.handler"
  runtime          = "python3.11"
  timeout          = 30
  filename         = data.archive_file.rotation_lambda.output_path
  source_code_hash = data.archive_file.rotation_lambda.output_base64sha256
}

resource "aws_lambda_permission" "secrets_manager" {
  statement_id  = "AllowSecretsManagerInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotation.function_name
  principal     = "secretsmanager.amazonaws.com"
}

resource "aws_secretsmanager_secret_rotation" "api_key" {
  secret_id           = aws_secretsmanager_secret.api_key.id
  rotation_lambda_arn = aws_lambda_function.rotation.arn

  rotation_rules {
    schedule_expression = "rate(14 days)"
  }
}

resource "aws_lambda_function" "this" {
  function_name = "${var.function_name}-${var.environment}"
  role          = var.role_arn
  package_type  = "Image"
  image_uri     = var.image_uri
  memory_size   = var.memory_size
  timeout       = var.timeout

  environment {
    variables = {
      APP_ENVIRONMENT                = var.environment
      APP_AWS_REGION                 = var.aws_region
      APP_API_KEY_SECRET_NAME        = var.api_key_secret_name
      APP_DYNAMODB_TABLE_ITINERARIES = var.dynamodb_table_itineraries
      APP_DYNAMODB_TABLE_CREDITS     = var.dynamodb_table_credits
      APP_UNLIMITED_TEST_CREDITS     = var.environment != "production" ? "true" : "false"
      APP_GOOGLE_MAPS_SECRET_NAME    = var.google_maps_secret_name
    }
  }

  depends_on = [aws_cloudwatch_log_group.this]
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.function_name}-${var.environment}"
  retention_in_days = 14
}

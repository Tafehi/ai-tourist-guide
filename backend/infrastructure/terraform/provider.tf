
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "ai-suggestion-app"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}


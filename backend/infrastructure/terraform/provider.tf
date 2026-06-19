
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "tripcraft-ai"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}


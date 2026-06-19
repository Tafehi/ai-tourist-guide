terraform {

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    random = {
      source = "hashicorp/random"
    }
    archive = {
      source = "hashicorp/archive"
    }
  }

  backend "s3" {
    bucket       = "fvc-terraform-state-bucket-dev"
    key          = "ai-suggestion-app/terraform.tfstate"
    region       = "eu-west-1"
    use_lockfile = true
  }
}
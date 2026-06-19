terraform {

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket       = "fvc-terraform-state-bucket-dev"
    key          = "tripcraft-ai/ecr/terraform.tfstate"
    region       = "eu-west-1"
    use_lockfile = true
  }
}

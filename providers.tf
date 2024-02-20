terraform {
  required_version = ">= 0.12"

  backend "s3" {
    // Configuration in backend/dev.hcl
    bucket         = "cloudicity-dev-tfstates"
    region         = "eu-west-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
    key            = "test_opensearchserverless/terraform.tfstate"
  }
}


# Set AWS provider region
provider "aws" {
  region = var.aws_region
}

data "terraform_remote_state" "cloudicity_core" {
  backend = "s3"

  config = {
    bucket = "cloudicity-${var.environment}-tfstates"
    region = var.aws_region
    key    = "infra-core/terraform.tfstate"
  }
}

# Gets access to the effective Account ID in which Terraform is authorized
data "aws_caller_identity" "current" {}
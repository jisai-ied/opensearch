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

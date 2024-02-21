data "terraform_remote_state" "core" {
  backend = "s3"

  config = {
    bucket = "cloudicity-${var.environment}-tfstates"
    region = var.aws_region
    key    = "infra-core/terraform.tfstate"
  }
}

# Gets access to the effective Account ID in which Terraform is authorized
data "aws_caller_identity" "current" {}
# ------------------------------------------------------------------------------
# Providers + shared lookups
# ------------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region
}

# Route 53 health-check metrics, CloudFront metrics, and root console sign-in
# events only exist in us-east-1.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

# Read-only view of the app root (infra/) for the CloudFront distribution and
# Lambda function to alarm on.
data "terraform_remote_state" "app" {
  backend = "s3"
  config = {
    bucket = "shaylee-portfolio-tf-state-2025"
    key    = "portfolio/terraform.tfstate"
    region = "us-east-2"
  }
}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

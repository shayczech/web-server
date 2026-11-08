# ------------------------------------------------------------------------------
# Providers + shared lookups
# ------------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region
}

# Route 53 health-check metrics and CloudFront metrics only exist in us-east-1.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

# Account-wide alert topics, owned by the aws-account repo. Looked up by name,
# never modified here.
data "aws_sns_topic" "alerts" {
  name = "web-server-alerts"
}

data "aws_sns_topic" "alerts_us_east_1" {
  provider = aws.us_east_1
  name     = "web-server-alerts"
}

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

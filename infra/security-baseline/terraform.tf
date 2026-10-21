# ------------------------------------------------------------------------------
# Security baseline: account-level detection, alerting, and the IAM guardrails
# the CI pipeline runs inside. Applied locally with admin credentials — never by
# CI — and kept in its own state key, which the deploy role can't read or write.
# A compromised pipeline therefore can't switch off its own monitoring or widen
# its own permissions.
# ------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket       = "shaylee-portfolio-tf-state-2025"
    key          = "security-baseline/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # >= 5.80 for aws_iam_role_policy_attachments_exclusive / _policies_exclusive.
      version = ">= 5.80, < 6.70"
    }
  }
}

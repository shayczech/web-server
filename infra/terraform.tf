# ------------------------------------------------------------------------------
# Terraform and backend configuration
# ------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket         = "shaylee-portfolio-tf-state-2025"
    key            = "portfolio/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    use_lockfile   = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
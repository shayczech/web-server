terraform {
  required_version = ">= 1.0"

  # 1. CONFIGURE S3 BACKEND FOR REMOTE STATE (with DynamoDB locking)
  backend "s3" {
    bucket         = "shaylee-portfolio-tf-state-2025"
    key            = "portfolio/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    dynamodb_table = "portfolio-tf-state-lock" # Locks state during apply/plan
  }

  # 2. KEEP ONLY THE AWS PROVIDER
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
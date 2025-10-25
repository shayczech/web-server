terraform {
  required_version = ">= 1.0"

  # 1. CONFIGURE S3 BACKEND FOR REMOTE STATE
  backend "s3" {
    bucket         = "shaylee-portfolio-tf-state-2025" # Your Bucket Name
    key            = "portfolio/terraform.tfstate"     # State file path inside the bucket
    region         = "us-east-2"                       # <--- CHANGE TO YOUR AWS REGION
    encrypt        = true                              # Enables server-side encryption
  }

  # 2. KEEP ONLY THE AWS PROVIDER
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
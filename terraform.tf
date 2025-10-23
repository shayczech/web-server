terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    # --- ADD THIS BLOCK ---
    # For generating the SSH key
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }

    # --- AND ADD THIS BLOCK ---
    # For saving the private key to your computer
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }

  required_version = ">= 1.0"
}
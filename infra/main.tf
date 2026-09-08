# ------------------------------------------------------------------------------
# Provider configuration
# ------------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region
}

# CloudFront requires its ACM certificate in us-east-1 regardless of where
# everything else lives.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

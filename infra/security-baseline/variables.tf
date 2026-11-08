# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------

variable "aws_region" {
  description = "Primary region (matches the app root)."
  type        = string
  default     = "us-east-2"
}

variable "server_name" {
  description = "Base name prefix (matches the app root)."
  type        = string
  default     = "web-server"
}

variable "domain_name" {
  description = "Site domain to health-check."
  type        = string
  default     = "shayleeczech.com"
}

variable "deploy_role_name" {
  description = "GitHub Actions OIDC deploy role (created outside Terraform)."
  type        = string
  default     = "GitHub-Actions-Deploy-Role"
}

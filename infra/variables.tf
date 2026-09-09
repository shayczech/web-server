# ------------------------------------------------------------------------------
# Root module variables
# ------------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-2"
}

variable "server_name" {
  description = "Base name prefix for all resources."
  type        = string
  default     = "web-server"
}

variable "domain_name" {
  description = "Primary domain for the site (used for ACM and Route 53)."
  type        = string
  default     = "shayleeczech.com"
}

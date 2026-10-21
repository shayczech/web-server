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

variable "alert_email" {
  description = "Where alarms, GuardDuty/Access Analyzer findings, root sign-ins, and budget alerts go."
  type        = string
}

variable "monthly_budget_usd" {
  description = "Monthly cost budget. Alerts at 40% actual, 100% actual, and 100% forecasted."
  type        = number
  default     = 25
}

variable "deploy_role_name" {
  description = "GitHub Actions OIDC deploy role (created outside Terraform)."
  type        = string
  default     = "GitHub-Actions-Deploy-Role"
}

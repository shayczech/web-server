# ------------------------------------------------------------------------------
# Provider configuration
# File structure per ha-migration-plan.md: vpc.tf, security_groups.tf, alb.tf, asg.tf.
# ------------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region
}

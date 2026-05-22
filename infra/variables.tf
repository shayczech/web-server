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

variable "ami_id" {
  description = "AMI ID for the EC2 instance (Ubuntu 22.04 in us-east-2)."
  type        = string
  default     = "ami-0cfde0ea8edd312d4"
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t2.micro"
}

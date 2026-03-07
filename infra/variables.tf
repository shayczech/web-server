# ------------------------------------------------------------------------------
# Root module variables (defaults used when not overridden)
# ------------------------------------------------------------------------------

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

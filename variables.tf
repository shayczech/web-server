# This file defines the "questions" our Terraform code will ask.
# We provide defaults so we don't have to enter them every time.

variable "ami_id" {
  description = "The AMI ID for the server (Ubuntu 22.04 in us-east-2)"
  type        = string
  default     = "ami-0cfde0ea8edd312d4"
}

variable "instance_type" {
  description = "The instance type to use"
  type        = string
  default     = "t2.micro"
}

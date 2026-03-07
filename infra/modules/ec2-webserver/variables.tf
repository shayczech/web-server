# ------------------------------------------------------------------------------
# EC2 web server module inputs
# ------------------------------------------------------------------------------

variable "ami_id" {
  description = "AMI ID for the EC2 instance."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type (e.g. t2.micro)."
  type        = string
}

variable "key_name" {
  description = "Name of the AWS key pair to attach to the instance."
  type        = string
}

variable "index_html_path" {
  description = "Local path to the index.html file to deploy (used by module if needed)."
  type        = string
}

variable "server_name" {
  description = "Base name for the server and related resources (e.g. security group, IAM role)."
  type        = string
  default     = "terraform-server"
}

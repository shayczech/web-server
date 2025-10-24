variable "ami_id" {
  description = "The AMI ID for the EC2 instance."
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance type (e.g., t2.micro)."
  type        = string
}

variable "key_name" {
  description = "The name of the AWS Key Pair to associate with the instance."
  type        = string
}

variable "private_key_pem" {
  description = "The content of the private key file for SSH access (used by provisioners)."
  type        = string
  sensitive   = true # Mark this as sensitive so Terraform doesn't log it
}

variable "index_html_path" {
  description = "The local path to the index.html file to be deployed."
  type        = string
}

variable "server_name" {
  description = "The base name for the server and related resources."
  type        = string
  default     = "terraform-server" # Provide a default value
}

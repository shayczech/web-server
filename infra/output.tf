
output "instance_public_ip" {
  description = "The public IP address of the EC2 instance."
  # Get the value from the 'instance_public_ip' output of the 'web_server' module
  value = module.web_server.instance_public_ip
}

output "instance_id" {
  description = "The ID of the EC2 instance."
  # Get the value from the 'instance_id' output of the 'web_server' module
  value = module.web_server.instance_id
}


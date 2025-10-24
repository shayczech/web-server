/*
output "instance_public_ip" {
  description = "The public IP address of the EC2 instance."
  # Reference the output named "public_ip" from the module block named "web_server"
  value = module.web_server.public_ip
}
*/
output "instance_public_ip" {
  description = "The public IP address of the EC2 instance."
  # Get the value from the 'instance_public_ip' output of the 'web_server' module
  value = module.web_server.instance_public_ip
}


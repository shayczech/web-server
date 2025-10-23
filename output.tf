output "instance_public_ip" {
  description = "The permanent public IP address (Elastic IP) of the EC2 instance, provided by the module."
  # Reference the output named "public_ip" from the module block named "web_server"
  value = module.web_server.public_ip
}
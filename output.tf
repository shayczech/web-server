output "instance_public_ip" {
<<<<<<< HEAD
  description = "The permanent public IP address (Elastic IP) of the EC2 instance, provided by the module."
  # Reference the output named "public_ip" from the module block named "web_server"
  value = module.web_server.public_ip
=======
  description = "Public IP address of our web server"
  value       = aws_instance.app_server.public_ip
>>>>>>> f33b80f2849dab297e53bcaeffb8f5eda3e28a04
}
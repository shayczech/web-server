output "instance_public_ip" {
  description = "The public IP address assigned to the EC2 instance."
  # Get the public_ip attribute directly from the aws_instance resource
  value       = aws_instance.app_server.public_ip
}

output "instance_id" {
  description = "The ID of the EC2 instance."
  # Get the id attribute directly from the aws_instance resource
  value       = aws_instance.app_server.id
}

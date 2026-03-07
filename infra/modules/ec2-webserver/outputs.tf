# ------------------------------------------------------------------------------
# EC2 web server module outputs
# ------------------------------------------------------------------------------

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance."
  value       = aws_instance.app_server.public_ip
}

output "instance_id" {
  description = "EC2 instance ID."
  value       = aws_instance.app_server.id
}

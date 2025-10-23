output "public_ip" {
  description = "The public IP address of the EC2 instance."
  value       = aws_eip.web_ip.public_ip
}

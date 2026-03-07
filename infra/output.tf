# ------------------------------------------------------------------------------
# Root module outputs (from web_server module)
# ------------------------------------------------------------------------------

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance."
  value       = module.web_server.instance_public_ip
}

output "instance_id" {
  description = "EC2 instance ID."
  value       = module.web_server.instance_id
}


# ------------------------------------------------------------------------------
# Root module outputs
# ------------------------------------------------------------------------------

output "alb_dns_name" {
  description = "ALB DNS name — Route 53 ALIAS points here."
  value       = aws_lb.web.dns_name
}

output "alb_zone_id" {
  description = "ALB hosted zone ID (for Route 53 ALIAS)."
  value       = aws_lb.web.zone_id
}

output "acm_certificate_arn" {
  description = "ACM certificate ARN."
  value       = aws_acm_certificate.web.arn
}

output "asg_name" {
  description = "ASG name (for deploy pipeline instance refresh)."
  value       = aws_autoscaling_group.web.name
}

output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}



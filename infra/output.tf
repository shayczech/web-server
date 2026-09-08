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

# --- New serverless stack (S3 + CloudFront + Lambda) ---

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (for cache invalidation in CI)."
  value       = aws_cloudfront_distribution.site.id
}

output "cloudfront_domain_name" {
  description = "CloudFront's own domain name — usable for pre-cutover verification."
  value       = aws_cloudfront_distribution.site.domain_name
}

output "s3_bucket_name" {
  description = "S3 bucket name for the static site (for `aws s3 sync` in CI)."
  value       = aws_s3_bucket.site.id
}

output "lambda_function_name" {
  description = "Lambda function name for the stats API (for CI code deploys)."
  value       = aws_lambda_function.stats_api.function_name
}


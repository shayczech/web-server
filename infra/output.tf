# ------------------------------------------------------------------------------
# Root module outputs
# ------------------------------------------------------------------------------

output "acm_certificate_arn" {
  description = "ACM certificate ARN (CloudFront, us-east-1)."
  value       = aws_acm_certificate.cloudfront.arn
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (for cache invalidation in CI)."
  value       = aws_cloudfront_distribution.site.id
}

output "cloudfront_domain_name" {
  description = "CloudFront's own domain name."
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

output "lambda_boundary_arn" {
  description = "Permissions boundary referenced by the app root's Lambda role."
  value       = aws_iam_policy.lambda_boundary.arn
}

output "alert_topic_arns" {
  description = "Account-wide SNS alert topics this root's alarms publish to (owned by the aws-account repo)."
  value       = [data.aws_sns_topic.alerts.arn, data.aws_sns_topic.alerts_us_east_1.arn]
}

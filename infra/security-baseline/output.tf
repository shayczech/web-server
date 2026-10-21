output "lambda_boundary_arn" {
  description = "Permissions boundary referenced by the app root's Lambda role."
  value       = aws_iam_policy.lambda_boundary.arn
}

output "alert_topic_arns" {
  description = "SNS alert topics (confirm the email subscription for each)."
  value       = [aws_sns_topic.alerts.arn, aws_sns_topic.alerts_us_east_1.arn]
}

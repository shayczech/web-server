# ------------------------------------------------------------------------------
# Availability + abuse alarms. Every alarm also sends its OK transition, so a
# recovery shows up in the inbox too.
# ------------------------------------------------------------------------------

# --- Is the site up? (Route 53 health check, probed from 3 regions) ---
resource "aws_route53_health_check" "site" {
  fqdn              = var.domain_name
  type              = "HTTPS"
  port              = 443
  resource_path     = "/"
  enable_sni        = true
  request_interval  = 30
  failure_threshold = 3
  regions           = ["us-east-1", "us-west-2", "eu-west-1"]

  tags = { Name = "${var.server_name}-site" }
}

resource "aws_cloudwatch_metric_alarm" "site_down" {
  provider            = aws.us_east_1
  alarm_name          = "${var.server_name}-site-down"
  alarm_description   = "https://${var.domain_name}/ is failing Route 53 health checks."
  namespace           = "AWS/Route53"
  metric_name         = "HealthCheckStatus"
  dimensions          = { HealthCheckId = aws_route53_health_check.site.id }
  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 2
  comparison_operator = "LessThanThreshold"
  threshold           = 1
  treat_missing_data  = "breaching"
  alarm_actions       = [aws_sns_topic.alerts_us_east_1.arn]
  ok_actions          = [aws_sns_topic.alerts_us_east_1.arn]
}

# --- Is CloudFront serving errors? Low traffic makes single errors swing the
# rate wildly, so require three consecutive bad 5-minute windows. ---
resource "aws_cloudwatch_metric_alarm" "cloudfront_5xx" {
  provider          = aws.us_east_1
  alarm_name        = "${var.server_name}-cloudfront-5xx"
  alarm_description = "CloudFront 5xx error rate above 10% for 15 minutes."
  namespace         = "AWS/CloudFront"
  metric_name       = "5xxErrorRate"
  dimensions = {
    DistributionId = data.terraform_remote_state.app.outputs.cloudfront_distribution_id
    Region         = "Global"
  }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 3
  comparison_operator = "GreaterThanThreshold"
  threshold           = 10
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts_us_east_1.arn]
  ok_actions          = [aws_sns_topic.alerts_us_east_1.arn]
}

# --- Stats API Lambda. The handler catches its own errors and returns 200, so
# Errors here means a crash or timeout. ---
locals {
  lambda_alarms = {
    errors = {
      metric      = "Errors"
      period      = 300
      threshold   = 0
      description = "Stats API Lambda crashed or timed out."
    }
    # Brief throttling during a bot burst is the concurrency cap doing its job;
    # only alert when it's sustained.
    throttles = {
      metric      = "Throttles"
      period      = 3600
      threshold   = 25
      description = "Stats API Lambda throttled more than 25 times in an hour (reserved concurrency 5) — sustained flood."
    }
    invocation_spike = {
      metric      = "Invocations"
      period      = 3600
      threshold   = 500
      description = "Over 500 stats API invocations in an hour. /api/* is edge-cached for 60s, so normal traffic is far below this."
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda" {
  for_each = local.lambda_alarms

  alarm_name          = "${var.server_name}-stats-api-${replace(each.key, "_", "-")}"
  alarm_description   = each.value.description
  namespace           = "AWS/Lambda"
  metric_name         = each.value.metric
  dimensions          = { FunctionName = data.terraform_remote_state.app.outputs.lambda_function_name }
  statistic           = "Sum"
  period              = each.value.period
  evaluation_periods  = 1
  comparison_operator = "GreaterThanThreshold"
  threshold           = each.value.threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

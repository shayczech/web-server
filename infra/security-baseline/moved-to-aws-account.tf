# ------------------------------------------------------------------------------
# Account-wide resources that moved to the aws-account repo on 2026-11-08.
#
# Each `removed` block drops the resource from this root's state WITHOUT
# destroying it. aws-account adopted every one of them with an `import` block
# (aws-account/infra/imports.tf). Keep this file: it's the record of the move,
# and deleting a block before its resource leaves this state would make the
# next plan destroy that resource.
# ------------------------------------------------------------------------------

# --- CloudTrail ---
removed {
  from = aws_s3_bucket.cloudtrail
  lifecycle { destroy = false }
}

removed {
  from = aws_s3_bucket_ownership_controls.cloudtrail
  lifecycle { destroy = false }
}

removed {
  from = aws_s3_bucket_public_access_block.cloudtrail
  lifecycle { destroy = false }
}

removed {
  from = aws_s3_bucket_lifecycle_configuration.cloudtrail
  lifecycle { destroy = false }
}

removed {
  from = aws_s3_bucket_policy.cloudtrail
  lifecycle { destroy = false }
}

removed {
  from = aws_cloudtrail.main
  lifecycle { destroy = false }
}

# --- GuardDuty ---
removed {
  from = aws_guardduty_detector.primary
  lifecycle { destroy = false }
}

removed {
  from = aws_guardduty_detector.us_east_1
  lifecycle { destroy = false }
}

removed {
  from = aws_cloudwatch_event_rule.guardduty
  lifecycle { destroy = false }
}

removed {
  from = aws_cloudwatch_event_target.guardduty
  lifecycle { destroy = false }
}

removed {
  from = aws_cloudwatch_event_rule.guardduty_us_east_1
  lifecycle { destroy = false }
}

removed {
  from = aws_cloudwatch_event_target.guardduty_us_east_1
  lifecycle { destroy = false }
}

# --- IAM Access Analyzer ---
removed {
  from = aws_accessanalyzer_analyzer.account
  lifecycle { destroy = false }
}

removed {
  from = aws_cloudwatch_event_rule.access_analyzer
  lifecycle { destroy = false }
}

removed {
  from = aws_cloudwatch_event_target.access_analyzer
  lifecycle { destroy = false }
}

# --- Root console sign-in alert ---
removed {
  from = aws_cloudwatch_event_rule.root_signin
  lifecycle { destroy = false }
}

removed {
  from = aws_cloudwatch_event_target.root_signin
  lifecycle { destroy = false }
}

# --- SNS alert topics ---
removed {
  from = aws_sns_topic.alerts
  lifecycle { destroy = false }
}

removed {
  from = aws_sns_topic_subscription.alerts_email
  lifecycle { destroy = false }
}

removed {
  from = aws_sns_topic.alerts_us_east_1
  lifecycle { destroy = false }
}

removed {
  from = aws_sns_topic_subscription.alerts_email_us_east_1
  lifecycle { destroy = false }
}

# --- Account budget ---
removed {
  from = aws_budgets_budget.monthly
  lifecycle { destroy = false }
}

# ------------------------------------------------------------------------------
# Threat detection → email: GuardDuty (medium+ findings), IAM Access Analyzer
# (new external-access findings), and any root console sign-in.
# ------------------------------------------------------------------------------

# --- GuardDuty, in both regions this account uses. IAM/STS events are global
# but this keeps CloudFront/ACM-side activity in us-east-1 covered too. ---
resource "aws_guardduty_detector" "primary" {
  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

resource "aws_guardduty_detector" "us_east_1" {
  provider                     = aws.us_east_1
  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

locals {
  # GuardDuty severity: 1-3.9 low, 4-6.9 medium, 7+ high. Low is mostly noise
  # for a personal account (except root usage, which has its own rule below).
  guardduty_pattern = jsonencode({
    source        = ["aws.guardduty"]
    "detail-type" = ["GuardDuty Finding"]
    detail        = { severity = [{ numeric = [">=", 4] }] }
  })
}

resource "aws_cloudwatch_event_rule" "guardduty" {
  name          = "${var.server_name}-guardduty-findings"
  event_pattern = local.guardduty_pattern
}

resource "aws_cloudwatch_event_target" "guardduty" {
  rule = aws_cloudwatch_event_rule.guardduty.name
  arn  = aws_sns_topic.alerts.arn
}

resource "aws_cloudwatch_event_rule" "guardduty_us_east_1" {
  provider      = aws.us_east_1
  name          = "${var.server_name}-guardduty-findings"
  event_pattern = local.guardduty_pattern
}

resource "aws_cloudwatch_event_target" "guardduty_us_east_1" {
  provider = aws.us_east_1
  rule     = aws_cloudwatch_event_rule.guardduty_us_east_1.name
  arn      = aws_sns_topic.alerts_us_east_1.arn
}

# --- IAM Access Analyzer: flags resources shared outside the account. Expect
# one finding for the GitHub OIDC trust on the deploy role — archive it. ---
resource "aws_accessanalyzer_analyzer" "account" {
  analyzer_name = "${var.server_name}-account"
  type          = "ACCOUNT"
}

resource "aws_cloudwatch_event_rule" "access_analyzer" {
  name = "${var.server_name}-access-analyzer-findings"
  event_pattern = jsonencode({
    source        = ["aws.access-analyzer"]
    "detail-type" = ["Access Analyzer Finding"]
    detail        = { status = ["ACTIVE"] }
  })
}

resource "aws_cloudwatch_event_target" "access_analyzer" {
  rule = aws_cloudwatch_event_rule.access_analyzer.name
  arn  = aws_sns_topic.alerts.arn
}

# --- Root console sign-in (success or failure). These events are delivered
# only in us-east-1 and need a trail to exist (cloudtrail.tf). ---
resource "aws_cloudwatch_event_rule" "root_signin" {
  provider = aws.us_east_1
  name     = "${var.server_name}-root-console-signin"
  event_pattern = jsonencode({
    "detail-type" = ["AWS Console Sign In via CloudTrail"]
    detail        = { userIdentity = { type = ["Root"] } }
  })
}

resource "aws_cloudwatch_event_target" "root_signin" {
  provider = aws.us_east_1
  rule     = aws_cloudwatch_event_rule.root_signin.name
  arn      = aws_sns_topic.alerts_us_east_1.arn
}

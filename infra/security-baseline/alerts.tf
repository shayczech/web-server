# ------------------------------------------------------------------------------
# SNS alert topics. CloudWatch alarms and EventBridge rules can only publish to
# a topic in their own region, so there's one per region. Each email
# subscription must be confirmed from the inbox once after the first apply.
# ------------------------------------------------------------------------------

data "aws_iam_policy_document" "alerts_topic" {
  for_each = {
    primary   = "arn:aws:sns:${var.aws_region}:${local.account_id}:${var.server_name}-alerts"
    us_east_1 = "arn:aws:sns:us-east-1:${local.account_id}:${var.server_name}-alerts"
  }

  statement {
    sid       = "OwnerFullAccess"
    actions   = ["sns:*"]
    resources = [each.value]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }
  }

  statement {
    sid       = "AllowAlarmsAndEventBridge"
    actions   = ["sns:Publish"]
    resources = [each.value]
    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com", "events.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }
}

resource "aws_sns_topic" "alerts" {
  name   = "${var.server_name}-alerts"
  policy = data.aws_iam_policy_document.alerts_topic["primary"].json
}

resource "aws_sns_topic_subscription" "alerts_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_sns_topic" "alerts_us_east_1" {
  provider = aws.us_east_1
  name     = "${var.server_name}-alerts"
  policy   = data.aws_iam_policy_document.alerts_topic["us_east_1"].json
}

resource "aws_sns_topic_subscription" "alerts_email_us_east_1" {
  provider  = aws.us_east_1
  topic_arn = aws_sns_topic.alerts_us_east_1.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

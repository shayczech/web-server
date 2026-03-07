# ------------------------------------------------------------------------------
# CloudWatch: log group and dashboard for Nginx access logs
# Log group name must match the agent config (ansible/files/amazon-cloudwatch-agent.json).
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "web_server_access" {
  name              = "web-server-access-logs"
  retention_in_days = 30
  tags = {
    Name = "${var.server_name}-nginx-access"
  }
}

resource "aws_cloudwatch_dashboard" "web_server" {
  dashboard_name = "${var.server_name}-nginx-logs"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "log"
        x      = 0
        y      = 0
        width  = 24
        height = 6
        properties = {
          title  = "Nginx requests over time"
          region = "us-east-2"
          query  = "SOURCE '${aws_cloudwatch_log_group.web_server_access.name}' | stats count() as requests by bin(5m)"
          view   = "timeSeries"
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 6
        width  = 24
        height = 8
        properties = {
          title  = "Recent Nginx access logs"
          region = "us-east-2"
          query  = "SOURCE '${aws_cloudwatch_log_group.web_server_access.name}' | fields @timestamp, @message | sort @timestamp desc | limit 50"
          view   = "table"
        }
      }
    ]
  })
}

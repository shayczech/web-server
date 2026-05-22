# ------------------------------------------------------------------------------
# GitHub Actions deploy role: SSM pipeline metrics (IaC count + Snyk security score)
# The JSON in policies/terraform-ha-deploy-policy.json must also be synced to any
# customer-managed policy attached to this role in IAM (console or policy version).
# ------------------------------------------------------------------------------

data "aws_iam_role" "github_actions_deploy" {
  name = var.github_actions_deploy_role_name
}

resource "aws_iam_role_policy" "github_actions_deploy_ssm_metrics" {
  name = "${var.server_name}-github-deploy-ssm-metrics"
  role = data.aws_iam_role.github_actions_deploy.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "PipelineMetricsPut"
        Effect = "Allow"
        Action = ["ssm:PutParameter"]
        Resource = [
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/web-server/iac-resource-count",
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/web-server/security-score",
        ]
      }
    ]
  })
}

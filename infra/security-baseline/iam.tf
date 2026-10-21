# ------------------------------------------------------------------------------
# IAM guardrails for the CI pipeline.
# ------------------------------------------------------------------------------

# --- Permissions boundary for the stats API Lambda role. The deploy role can
# only create/modify that role with this boundary attached (see
# ../policies/github-deploy-role.json), and can't edit this policy, so the
# function's effective permissions are capped here regardless of what the app
# root attaches. ---
resource "aws_iam_policy" "lambda_boundary" {
  name        = "${var.server_name}-lambda-boundary"
  description = "Permissions boundary for the stats API Lambda role. Managed by infra/security-baseline."
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "OwnLogs"
        Effect = "Allow"
        Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = [
          "arn:aws:logs:${var.aws_region}:${local.account_id}:log-group:/aws/lambda/${var.server_name}-*",
          "arn:aws:logs:${var.aws_region}:${local.account_id}:log-group:/aws/lambda/${var.server_name}-*:*",
        ]
      },
      {
        Sid    = "StatsParameters"
        Effect = "Allow"
        Action = "ssm:GetParameter"
        Resource = [for p in ["iac-resource-count", "security-score", "github-token"] :
          "arn:aws:ssm:${var.aws_region}:${local.account_id}:parameter/${var.server_name}/${p}"
        ]
      },
      {
        Sid       = "DecryptSecureStringViaSsmOnly"
        Effect    = "Allow"
        Action    = "kms:Decrypt"
        Resource  = "*"
        Condition = { StringEquals = { "kms:ViaService" = "ssm.${var.aws_region}.amazonaws.com" } }
      },
    ]
  })
}

# --- The deploy role's one and only policy. The *_exclusive resources detach
# every other managed policy and delete every inline policy on the role —
# replacing the accumulated EC2-era grants (including iam:CreateRole +
# iam:AttachRolePolicy on "*", i.e. a path to admin). ---
data "aws_iam_role" "github_deploy" {
  name = var.deploy_role_name
}

resource "aws_iam_policy" "github_deploy" {
  name        = "${var.server_name}-github-deploy"
  description = "Least-privilege policy for the GitHub Actions deploy role. Managed by infra/security-baseline."
  policy      = file("${path.module}/../policies/github-deploy-role.json")
}

resource "aws_iam_role_policy_attachments_exclusive" "github_deploy" {
  role_name   = data.aws_iam_role.github_deploy.name
  policy_arns = [aws_iam_policy.github_deploy.arn]
}

resource "aws_iam_role_policies_exclusive" "github_deploy" {
  role_name    = data.aws_iam_role.github_deploy.name
  policy_names = []
}

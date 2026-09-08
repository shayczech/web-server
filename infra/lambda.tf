# ------------------------------------------------------------------------------
# Lambda: the one dynamic endpoint (/api/stats), replacing the Express server
# that ran on the ASG's EC2 instance. Fronted by API Gateway (see api_gateway.tf)
# rather than a Lambda Function URL — this account rejects *every* form of
# unauthenticated Function URL invocation (AuthType AWS_IAM via CloudFront OAC,
# and AuthType NONE with an explicit public resource-policy statement both
# returned a hard AccessDeniedException at the Lambda invoke layer itself,
# confirmed even against a brand-new, from-scratch probe function with no
# other config — not an Organizations SCP, since this account isn't part of
# an Organization). API Gateway HTTP APIs don't hit whatever this restriction
# is, and are the more conventional pattern for this anyway. A shared-secret
# header from CloudFront (checked in the handler) still gates access to real
# data if someone calls the API Gateway URL directly, bypassing CloudFront.
# ------------------------------------------------------------------------------

resource "random_password" "origin_secret" {
  length  = 32
  special = false
}

resource "aws_iam_role" "lambda_exec" {
  name = "${var.server_name}-lambda-stats-api-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Same 3 SSM parameters the EC2 role could read — same least-privilege shape.
# A standalone managed policy + attachment, not an inline aws_iam_role_policy —
# creating/attaching a managed policy uses iam:CreatePolicy/AttachRolePolicy,
# which the deploying identity already has; inline role policies would need
# iam:PutRolePolicy, which it doesn't.
resource "aws_iam_policy" "lambda_ssm_read" {
  name = "${var.server_name}-lambda-ssm-read"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "ssm:GetParameter"
      Resource = [
        "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/web-server/iac-resource-count",
        "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/web-server/security-score",
        "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/web-server/github-token",
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_ssm_read" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_ssm_read.arn
}

resource "aws_lambda_function" "stats_api" {
  function_name    = "${var.server_name}-stats-api"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  architectures    = ["arm64"]
  timeout          = 10
  memory_size      = 128
  filename         = "${path.module}/lambda/stats-api.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/stats-api.zip")

  environment {
    variables = {
      ORIGIN_SECRET = random_password.origin_secret.result
    }
  }

  tags = { Name = "${var.server_name}-stats-api" }
}

resource "aws_cloudwatch_log_group" "lambda_stats_api" {
  name              = "/aws/lambda/${aws_lambda_function.stats_api.function_name}"
  retention_in_days = 30
}

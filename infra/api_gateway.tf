# ------------------------------------------------------------------------------
# API Gateway HTTP API: fronts the Lambda function for CloudFront's /api/*
# behavior. See lambda.tf for why this is used instead of a Function URL.
# ------------------------------------------------------------------------------

resource "aws_apigatewayv2_api" "stats_api" {
  name          = "${var.server_name}-stats-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "stats_api" {
  api_id                 = aws_apigatewayv2_api.stats_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.stats_api.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "stats_api" {
  api_id    = aws_apigatewayv2_api.stats_api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.stats_api.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.stats_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stats_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.stats_api.execution_arn}/*/*"
}

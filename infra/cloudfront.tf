# ------------------------------------------------------------------------------
# CloudFront: single distribution fronting the S3 static site and the Lambda
# stats API, both via Origin Access Control (SigV4) so neither origin is
# reachable except through this distribution.
# ------------------------------------------------------------------------------

resource "aws_cloudfront_origin_access_control" "s3" {
  name                              = "${var.server_name}-s3-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_function" "viewer_request" {
  name    = "${var.server_name}-viewer-request"
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = file("${path.module}/cf-functions/viewer-request.js")
}

# Security headers for every response. No Content-Security-Policy: every page
# uses inline <script> blocks and the Tailwind Play CDN (which injects inline
# styles at runtime), so a CSP would need 'unsafe-inline' for both and buy
# little. HSTS omits `preload` — that's hard to undo once submitted.
resource "aws_cloudfront_response_headers_policy" "security" {
  name = "${var.server_name}-security-headers"

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      override                   = true
    }
    content_type_options {
      override = true
    }
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
  }
}

# Replicates nginx's `add_header X-Robots-Tag "noindex, nofollow"` scoped to /p/*.
# A cache behavior takes one response headers policy, so this repeats the
# security headers above.
resource "aws_cloudfront_response_headers_policy" "noindex" {
  name = "${var.server_name}-noindex-p"

  custom_headers_config {
    items {
      header   = "X-Robots-Tag"
      value    = "noindex, nofollow"
      override = true
    }
  }

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      override                   = true
    }
    content_type_options {
      override = true
    }
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
  }
}

# /api/stats fans out to ~5 GitHub API calls per invocation, so cache it at the
# edge for 5 minutes (the "60s" in the name is from the original TTL; renaming
# would replace a policy the distribution is using). min_ttl must be > 0: the
# Lambda sends `Cache-Control: no-store` (aimed at browsers), which CloudFront
# would otherwise honor and never cache.
resource "aws_cloudfront_cache_policy" "api" {
  name        = "${var.server_name}-api-60s"
  min_ttl     = 300
  default_ttl = 300
  max_ttl     = 300

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_origin_request_policy" "all_viewer_except_host" {
  name = "Managed-AllViewerExceptHostHeader"
}

resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = [var.domain_name, "www.${var.domain_name}"]
  price_class         = "PriceClass_100"

  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "s3-site"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
  }

  origin {
    domain_name = trimprefix(aws_apigatewayv2_api.stats_api.api_endpoint, "https://")
    origin_id   = "lambda-stats-api"

    custom_header {
      name  = "X-Origin-Verify"
      value = random_password.origin_secret.result
    }

    custom_origin_config {
      http_port              = 80
      https_port              = 443
      origin_protocol_policy  = "https-only"
      origin_ssl_protocols    = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "s3-site"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.viewer_request.arn
    }
  }

  ordered_cache_behavior {
    path_pattern            = "/p/*"
    target_origin_id        = "s3-site"
    viewer_protocol_policy  = "redirect-to-https"
    allowed_methods         = ["GET", "HEAD"]
    cached_methods          = ["GET", "HEAD"]
    cache_policy_id         = data.aws_cloudfront_cache_policy.caching_optimized.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.noindex.id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.viewer_request.arn
    }
  }

  ordered_cache_behavior {
    path_pattern              = "/api/*"
    target_origin_id          = "lambda-stats-api"
    viewer_protocol_policy    = "redirect-to-https"
    allowed_methods           = ["GET", "HEAD", "OPTIONS"]
    cached_methods            = ["GET", "HEAD"]
    cache_policy_id           = aws_cloudfront_cache_policy.api.id
    origin_request_policy_id  = data.aws_cloudfront_origin_request_policy.all_viewer_except_host.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id
    # No function_association here — the clean-URL/.html rewrite doesn't apply to API paths.
  }

  custom_error_response {
    error_code         = 403
    response_code      = 404
    response_page_path = "/404.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/404.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cloudfront.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = { Name = "${var.server_name}-cdn" }
}

# ------------------------------------------------------------------------------
# Route 53: hosted zone lookup + apex/www ALIAS records → CloudFront.
# ------------------------------------------------------------------------------

data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# evaluate_target_health must be false — Route53 rejects true for CloudFront
# alias targets, unlike the ALB targets these records used to point at.
resource "aws_route53_record" "apex" {
  allow_overwrite = true
  zone_id         = data.aws_route53_zone.main.zone_id
  name            = var.domain_name
  type            = "A"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = "Z2FDTNDATAQYW2" # fixed CloudFront hosted-zone-id constant
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www" {
  allow_overwrite = true
  zone_id         = data.aws_route53_zone.main.zone_id
  name            = "www.${var.domain_name}"
  type            = "A"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

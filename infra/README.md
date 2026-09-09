# Infrastructure (Terraform)

Backend and providers in `terraform.tf`. Flat layout, no modules: S3 + CloudFront
+ Lambda + API Gateway (no VPC, no EC2 — see "History" below).

## Layout

| File / module        | Purpose |
|-----------------------|---------|
| `main.tf`             | Providers (`us-east-2` default, `us_east_1` alias for CloudFront's ACM cert), `data.aws_caller_identity.current` |
| `s3.tf`               | Private S3 bucket for the static site (OAC-only access, no public bucket policy) |
| `cloudfront.tf`       | Distribution, S3 Origin Access Control, CloudFront Function (clean URLs + legacy redirect), response headers policy |
| `cf-functions/`       | CloudFront Function source (`viewer-request.js`) |
| `acm_cloudfront.tf`   | ACM cert for CloudFront (must be us-east-1), DNS validation |
| `lambda.tf`           | Lambda function for `/api/stats`, exec role scoped to 3 SSM `GetParameter` ARNs only |
| `api_gateway.tf`      | HTTP API fronting the Lambda (see note below on why not a Function URL) |
| `route53.tf`          | Hosted zone lookup, apex/www ALIAS records → CloudFront |
| `variables.tf`        | Root variables (`aws_region`, `server_name`, `domain_name`) |
| `output.tf`           | Root outputs (CloudFront, S3 bucket, Lambda function name) |
| `policies/`           | IAM policy JSON attached to the GitHub Actions OIDC deploy role |

## Site content

The static site (`site/`) is synced directly to the S3 bucket (`aws s3 sync`) by
`.github/workflows/deploy-content.yml`. CloudFront serves it at `/` and `/p/recipes`.
The dynamic stats endpoint (`site/api/`) is a Lambda function deployed by
`.github/workflows/deploy.yml`.

## Why API Gateway, not a Lambda Function URL

Function URLs were tried first (both `AuthType=AWS_IAM` behind CloudFront's OAC,
and `AuthType=NONE` with an explicit public resource-policy statement). Both were
rejected with a hard `AccessDeniedException` at the Lambda invoke layer itself —
confirmed with a disposable from-scratch probe function with no other config, and
not caused by an Organizations SCP (this account isn't in an Organization). API
Gateway sidesteps whatever that restriction is. A shared-secret header from
CloudFront's origin config, checked in the Lambda handler, still gates real data
if the API Gateway URL is called directly.

## History

Through September 2026 this ran on a VPC + ALB + Auto Scaling Group + EC2 + NAT
Gateway (~$64/mo). It was replaced with this serverless stack (~$2-5/mo) — same
site, same `/api/stats` behavior, no NAT Gateway/ALB/EC2 to patch or pay for.

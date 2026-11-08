# Security baseline (Terraform)

This site's IAM guardrails and availability alarms. **Applied locally with
admin credentials, never by CI.** It has its own state key
(`security-baseline/terraform.tfstate`), which the deploy role can't read or
write. A compromised pipeline therefore can't disable its own monitoring or
widen its own permissions.

| File | What it does |
|------|--------------|
| `iam.tf` | Lambda permissions boundary; the deploy role's single least-privilege policy (`../policies/github-deploy-role.json`), with every other attached/inline policy stripped |
| `monitoring.tf` | Route 53 health check on `/` → site-down alarm; CloudFront 5xx rate; Lambda errors/throttles/invocation spike |
| `main.tf` | Providers, a read-only view of the app root's state, and lookups of the account-wide alert topics by name |
| `moved-to-aws-account.tf` | `removed` blocks for the account-wide resources that moved out (see below). Keep it |

## Account-wide resources live in `aws-account`

CloudTrail, GuardDuty, IAM Access Analyzer, the root sign-in alert, the
`web-server-alerts` SNS topics and the account budget moved to the private
[`shayczech/aws-account`](https://github.com/shayczech/aws-account) repo on
2026-11-08, because the account now hosts more than one project. Nothing was
recreated: `aws-account` imported each resource and this root dropped it from
state with `removed { lifecycle { destroy = false } }`. The alarms here still
publish to the same topics, found by name with `data "aws_sns_topic"`.

## How to apply

Sign in with `aws login --profile admin`; Terraform uses the `admin-tf`
profile, which serves the same short-lived credentials (setup is in the
`aws-account` README).

```sh
cd infra/security-baseline
AWS_PROFILE=admin-tf terraform init
AWS_PROFILE=admin-tf terraform plan -out=apply.tfplan
AWS_PROFILE=admin-tf terraform apply apply.tfplan
```

No variables are required. Read the plan before applying: a destroy of
anything in `moved-to-aws-account.tf` is a stop.

If a CI apply fails with `AccessDenied`, the error names the missing action.
Add it to `../policies/github-deploy-role.json`, apply here, and re-run the
workflow.

## History

The first apply (October 2026) replaced the deploy role's accumulated EC2-era
policies with the single policy in `../policies/`. A backup of the old
policies was taken to `~/deploy-role-backup` beforehand. `Portfolio-DevSecOps-Policy`
and `terraform-serverless-deploy-policy{,-2}` were left orphaned by that change
and can be deleted.

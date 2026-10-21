# Security baseline (Terraform)

Account-level detection, alerting, and the IAM guardrails the CI pipeline runs
inside. **Applied locally with admin credentials, never by CI.** It has its own
state key (`security-baseline/terraform.tfstate`), which the deploy role can't
read or write. A compromised pipeline therefore can't disable its own
monitoring or widen its own permissions.

| File | What it does |
|------|--------------|
| `iam.tf` | Lambda permissions boundary; the deploy role's single least-privilege policy (`../policies/github-deploy-role.json`), with every other attached/inline policy stripped |
| `cloudtrail.tf` | Multi-region management-event trail → private S3 bucket (1-year expiry, log-file validation) |
| `detection.tf` | GuardDuty (us-east-2 + us-east-1, medium+ findings emailed), IAM Access Analyzer (active findings emailed), root console sign-in alert |
| `monitoring.tf` | Route 53 health check on `/` → site-down alarm; CloudFront 5xx rate; Lambda errors/throttles/invocation spike |
| `budgets.tf` | Monthly cost budget, emails at 40% / 100% actual and 100% forecasted |
| `alerts.tf` | SNS topics (one per region) with email subscriptions |

Expected added cost: a few dollars a month (health check + ~6 alarms +
CloudTrail S3 storage), plus GuardDuty after its 30-day trial (the trial's
usage page shows the projected cost).

## First-time apply

Order matters: the app root (`infra/`) references the Lambda boundary created
here, and the new deploy-role policy is what grants CI permission to attach it.

1. **Back up the deploy role's current policies.** `aws_iam_role_policies_exclusive`
   deletes the inline policies, and their content isn't in git anywhere:

   ```sh
   mkdir -p ~/deploy-role-backup && cd ~/deploy-role-backup
   R=GitHub-Actions-Deploy-Role
   for p in $(aws iam list-role-policies --role-name $R --query PolicyNames --output text); do
     aws iam get-role-policy --role-name $R --policy-name "$p" --query PolicyDocument > "inline-$p.json"
   done
   aws iam list-attached-role-policies --role-name $R > attached.json
   ```

2. **Apply** (admin credentials):

   ```sh
   cd infra/security-baseline
   echo 'alert_email = "you@example.com"' > terraform.tfvars   # gitignored
   terraform init
   terraform apply
   ```

   The plan should show the 4 managed policies being detached and the 5 inline
   ones being removed from `GitHub-Actions-Deploy-Role`.

3. **Confirm both SNS subscription emails** (one from us-east-2, one from
   us-east-1). Alarms don't deliver until you do.

4. **Merge to `main`** (or re-run *DevSecOps Portfolio CI/CD* via
   `workflow_dispatch`). The CI apply adds the boundary to the Lambda role and
   rolls out the app-root changes under the new least-privilege role.

If the CI apply fails with `AccessDenied`, the error names the missing action.
Add it to `../policies/github-deploy-role.json`, re-apply here, and re-run the
workflow. To roll back entirely, re-attach the ARNs in `attached.json` and
`put-role-policy` the backed-up inline documents.

After it's settled, `Portfolio-DevSecOps-Policy` and
`terraform-serverless-deploy-policy{,-2}` are orphaned managed policies and can
be deleted.

# Serverless DevSecOps Portfolio: CI/CD, Terraform, and Account Security Baseline

The source for [shayleeczech.com](https://shayleeczech.com): a static portfolio site plus one small API, running on a fully serverless AWS stack and deployed by GitHub Actions. Everything is defined as code and the pipeline scans before it deploys.

## Architecture

```
Visitor → Route 53 → CloudFront ─┬─ (static pages) ─→ private S3 bucket   [Origin Access Control]
                (CloudFront       └─ (/api/*)       ─→ API Gateway (HTTP API) → Lambda (Node.js 22, arm64)
                 Function at edge)
```

* **Edge:** CloudFront terminates TLS with an ACM certificate (us-east-1). A CloudFront Function handles clean URLs and one legacy redirect.
* **Static site:** `site/` is synced to a private S3 bucket. The bucket allows reads only from this CloudFront distribution.
* **API:** `GET /api/stats` runs in a Lambda behind API Gateway. It reads three SSM parameters and calls the public GitHub API. No VPC, no servers to patch.
* **Why API Gateway and not a Lambda Function URL:** see [`infra/README.md`](infra/README.md).
* **Cost:** about $2–5 per month. The previous VPC + ALB + Auto Scaling + EC2 + NAT Gateway version cost about $64 per month and was retired in September 2026.

## Repository layout

| Path | What it holds |
|---|---|
| `site/` | Static pages (`index`, `resume`, `architecture`, `grc`), recipes under `site/p/`, and the Lambda source under `site/api/` |
| `infra/` | Terraform for the app, applied by CI. See [`infra/README.md`](infra/README.md) |
| `infra/security-baseline/` | Separate Terraform root applied locally with admin credentials: the deploy role's permissions, the Lambda permissions boundary, and the site's alarms. See [its README](infra/security-baseline/README.md) |
| `.github/workflows/` | `deploy.yml`, `deploy-content.yml`, `snyk.yml`, `codeql.yml` |
| `.github/dependabot.yml` | Weekly grouped updates for npm, GitHub Actions, and Terraform |

## Pipeline

| Workflow | Trigger | What it does |
|---|---|---|
| `deploy-content.yml` | Push to `main` touching `site/**` (excluding `site/api/**`), or manual | Syncs `site/` to S3, invalidates CloudFront |
| `deploy.yml` | Push to `main` touching `infra/**` (excluding `infra/security-baseline/**`) or `site/api/**`, or manual | Runs the Snyk gate, then Terraform apply, builds and deploys the Lambda, publishes the security score and resource count to SSM, invalidates `/api/*` |
| `snyk.yml` | Pull requests touching `site/api/**`, weekly, and as the gate in `deploy.yml` | Dependency scan of the Lambda; fails on high or critical findings |
| `codeql.yml` | Push and pull requests to `main`, weekly | CodeQL static analysis for JavaScript |

Deploys queue instead of running side by side, so back-to-back merges don't race for the Terraform state lock.

## Security design

* **No long-lived AWS credentials.** GitHub Actions assumes a deploy role through OIDC.
* **Scan job has no cloud access.** `snyk.yml` runs npm and the Snyk CLI without an OIDC token. Only the deploy job gets one, and it runs no third-party package code (`npm ci --ignore-scripts`).
* **CI can't widen its own permissions.** The deploy role has a single least-privilege policy (`infra/policies/github-deploy-role.json`). That policy, the Lambda permissions boundary, and this site's alarms live in `security-baseline/`, which has its own Terraform state that the deploy role cannot read or write.
* **Detection and alerting:** site-down and error-rate alarms live here. The account-wide controls (multi-region CloudTrail, GuardDuty, IAM Access Analyzer, root sign-in alert, the monthly cost budget and the SNS alert topics) live in a separate private account-baseline repo, because the AWS account now hosts more than one project. Every alert emails through those shared SNS topics.
* **Supply chain:** third-party actions are pinned to commit SHAs, and Dependabot proposes updates weekly.
* **State:** remote Terraform state in an encrypted S3 bucket with S3 lockfile locking.

## Running it

* **Deploy:** merge to `main`. The workflow that matches the changed paths runs. Either can also be started from the Actions tab.
* **Security baseline:** apply it locally as described in [its README](infra/security-baseline/README.md). CI never applies it.
* **Pause deploys:** disable `deploy.yml` and `deploy-content.yml` in the repository's Actions tab.

## Author

**Shaylee Czech** — Security Automation & DevSecOps Engineer | CISSP  
Building automated, secure, observable cloud infrastructure. Drawn to mission-driven work (quantum, space, AI/ML, clean energy, healthcare).  
[LinkedIn](https://www.linkedin.com/in/shayleeczech) | [GitHub](https://github.com/shayczech)

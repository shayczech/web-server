# Infrastructure (Terraform)

Backend and providers in `terraform.tf`. Flat layout: one VPC, ALB, ASG (no modules).

## Layout

| File / module      | Purpose |
|-------------------|---------|
| `main.tf`         | Provider only (`region = var.aws_region`) |
| `vpc.tf`          | VPC, subnets (2 AZs), IGW, NAT Gateway, route tables |
| `security_groups.tf` | ALB SG (80/443 from internet), EC2 SG (80 from ALB only) |
| `alb.tf`          | ACM cert, ALB, target group, HTTP→HTTPS redirect, HTTPS listener, Route 53 ALIAS |
| `asg.tf`          | EC2 IAM role (CloudWatch + SSM), Launch Template, ASG (desired=1, min=1, max=4) |
| `userdata.sh`     | Instance bootstrap: Docker, CloudWatch Agent, clone repo, stats-api + Nginx |
| `variables.tf`    | Root variables (`aws_region`, `server_name`, `domain_name`, etc.) |
| `output.tf`       | Root outputs (ALB, ASG name, ACM) |
| `policies/`       | IAM policy JSON for GitHub Actions / manual attachment |
| `CLEANUP.md`      | How to clean up extra EC2 instances and control cost |

## GitHub token for stats API (optional)

The stats API calls GitHub (commits, Terraform file count, Actions runs). Unauthenticated requests are limited to **60/hour**, so the API can return zeros when rate limited. To fix:

1. Create a [GitHub personal access token](https://github.com/settings/tokens) (classic or fine-grained) with `repo` (or minimal read) scope.
2. Store it in SSM as a **SecureString** in the **same region** as this stack:

   ```bash
   aws ssm put-parameter \
     --name /web-server/github-token \
     --type SecureString \
     --value "ghp_xxxxxxxxxxxx" \
     --region us-east-2
   ```

3. Apply Terraform (EC2 role already has permission to read this parameter). The stats API reads the token from SSM at startup; restart the stats-api container or run an instance refresh to pick it up.

## Cleanup and cost

If you see more EC2 instances than expected (e.g. 4 running, 4 terminated), see **[CLEANUP.md](CLEANUP.md)** for steps to scale in the managed ASG and remove any orphaned ASGs or instances.

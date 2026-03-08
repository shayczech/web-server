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

## Cleanup and cost

If you see more EC2 instances than expected (e.g. 4 running, 4 terminated), see **[CLEANUP.md](CLEANUP.md)** for steps to scale in the managed ASG and remove any orphaned ASGs or instances.

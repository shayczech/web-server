# Infrastructure (Terraform)

Backend and providers in `terraform.tf`. File structure follows ha-migration-plan.md (flat layout, no modules for new resources).

## Layout

| File / module      | Purpose |
|-------------------|---------|
| `main.tf`         | Provider only (`region = var.aws_region`) |
| `vpc.tf`          | VPC, subnets (2 AZs), IGW, NAT Gateway, route tables (inline) |
| `security_groups.tf` | ALB SG (80/443 from internet), EC2 SG (80 from ALB only) |
| `alb.tf`          | ACM cert, ALB, target group, HTTP→HTTPS redirect, HTTPS listener, Route 53 ALIAS (apex + www) |
| `asg.tf`          | EC2 IAM role (CloudWatch + SSM), Launch Template, ASG (2 AZs, private subnets) |
| `userdata.sh`     | Instance bootstrap: Docker, CloudWatch Agent, clone repo, stats-api + Nginx |
| `web_server.tf`   | Legacy single EC2 module — remove with `modules/ec2-webserver` when cutover is done |
| `variables.tf`    | Root variables (`aws_region`, `server_name`, `domain_name`, etc.) |
| `output.tf`       | Root outputs (ALB, ASG, ACM; legacy instance outputs optional) |
| `modules/ec2-webserver` | Legacy; delete after ALB+ASG is live and state is migrated |
| `policies/`       | IAM policy JSON (attach to roles manually) |

## Cutover to HA

Before first apply of the new stack: run `terraform state rm` on the legacy `module.web_server.*` resources (see ha-migration-plan.md). Then delete `web_server.tf` and `modules/ec2-webserver/` so only the new ALB+ASG stack is applied.

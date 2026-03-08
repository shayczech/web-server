# Secure DevSecOps Portfolio — HA CI/CD Pipeline

This project demonstrates a secure, highly available web application deployment with a DevSecOps CI/CD pipeline. It highlights Infrastructure-as-Code (IaC), shift-left security, and continuous deployment orchestrated by GitHub Actions.

The architecture is **ALB + Auto Scaling Group across two AZs**: custom VPC, private subnets for EC2, ACM for SSL, and rolling instance refresh for zero-downtime deploys.

## Project Overview

* **Site content:** Live pages and stats API live in **`site/`** (HTML in `site/`, Node.js API in `site/api/`). The `ansible/` directory is kept for historical playbooks and config only; the pipeline and instance userdata use `site/`.
* **Infrastructure:** AWS custom VPC (public subnets for ALB, private subnets for EC2), Application Load Balancer, Auto Scaling Group (2 AZs), ACM certificate, Route 53 ALIAS records.
* **State Management:** Remote Terraform state in an encrypted S3 bucket with DynamoDB state locking.
* **Architecture:**
  * **ALB** terminates HTTPS (ACM), redirects HTTP→HTTPS, forwards to a target group.
  * **EC2 instances** (ASG, private subnets) run Docker: Nginx (HTTP only, rate-limited) and a Node.js stats API. No public IPs; traffic only from the ALB.
* **Deployment:** Push to `main` → Snyk scan → Terraform apply → ASG instance refresh. New instances boot via Launch Template userdata (Docker, CloudWatch Agent, clone repo, build and run containers).
* **Security:** IAM instance profiles (CloudWatch, SSM only); no SSH to instances (SSM Session Manager). Snyk (SAST) in pipeline; Nginx rate limiting (5 req/s, 429). ACM for certificate lifecycle.
* **Monitoring:** CloudWatch Agent on each instance; Nginx access logs to CloudWatch. GRC Compliance Dashboard on the site maps controls to NIST, CIS, HIPAA.

## Technical Stack

| **Area** | **Tools** |
| :--- | :--- |
| Infrastructure as Code | Terraform (VPC, ALB, ASG, ACM, Route 53, security groups) |
| CI/CD | GitHub Actions (Snyk, Terraform apply, ASG instance refresh) |
| Cloud Platform | AWS (VPC, ALB, ASG, EC2, ACM, Route 53, IAM, CloudWatch) |
| Containers | Nginx (web/proxy), Node.js/Express (stats API) |
| Security | ACM (SSL), Snyk (SAST), Nginx rate limiting, IAM, GitHub OIDC |

## Deployment Workflow

1. **Push** to `main` triggers the workflow.
2. **Snyk** scans dependencies; build fails on high/critical vulnerabilities.
3. **Terraform** init, validate, apply (provisions/updates VPC, ALB, ASG, etc.).
4. **ASG instance refresh** starts a rolling replacement so new instances boot with the latest userdata and content.
5. **Live:** Site is served via ALB; instances in private subnets register with the target group and receive traffic.

## Future Enhancements

* **Observability:** CloudWatch custom metrics and alarms (e.g., 429 rate, API latency).
* **Scope-down IAM:** Replace broad Terraform-runner permissions with least-privilege policies.

## Author

**Shaylee Czech** — Senior Infrastructure / Platform Engineer | CISSP  
Building automated, secure, observable cloud infrastructure. Drawn to mission-driven work (quantum, space, AI/ML, clean energy, healthcare).  
[LinkedIn](https://www.linkedin.com/in/shayleeczech) | [GitHub](https://github.com/shayczech)

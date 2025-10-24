# Terraform-Deployed Secure Web Server

This project provisions a hardened Ubuntu EC2 instance in AWS using Terraform. It installs Docker and deploys an HTTPS-enabled NGINX web service, demonstrating cloud automation, Infrastructure-as-Code (IaC), and practical DevSecOps principles.

---

## Project Overview
- **Infrastructure:** AWS EC2 t2.micro instance with an Elastic IP  
- **Automation:** Modular Terraform design with variables and outputs  
- **Configuration:** cloud-init (`user_data`) automates Docker and NGINX installation  
- **Security:** Enforced least privilege, firewall configuration, and TLS via Let's Encrypt  
- **Networking:** Custom domain mapped to Elastic IP  
- **Resilience:** Auto-starting Docker container with persistent data volume  

---

## Technical Stack
| Area | Tools |
|------|--------|
| Infrastructure as Code | Terraform |
| Cloud Platform | AWS (EC2, VPC, Elastic IP) |
| Operating System | Ubuntu 24.04 LTS |
| Containers | Docker and NGINX |
| Security | Let's Encrypt TLS Certificates |
| Automation | Bash (cloud-init user_data) |

---

## Deployment Workflow
1. Terraform provisions the AWS resources, including networking, security groups, and EC2 instance.  
2. The instance bootstraps itself using a cloud-init script (`user_data`) that installs Docker and runs NGINX Proxy Manager.  
3. The container automatically requests and manages an HTTPS certificate using Let's Encrypt.  
4. The domain is configured to resolve to the Elastic IP, serving secure traffic via NGINX.  

---

## Future Enhancements
- Integrate CloudWatch for log aggregation and alerting.  
- Implement IAM roles for principle of least privilege.  
- Add CI/CD deployment for automatic updates to hosted content.  
- Expand the stack to include a containerized portfolio application.  

---

## Author
**Shaylee Czech**  
Cloud and Security Engineering Professional | CISSP Candidate  
[LinkedIn](https://www.linkedin.com/in/shayleeczech) | [GitHub](https://github.com/shayczech)

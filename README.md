# Terraform-Deployed Secure DevSecOps CI/CD Pipeline

This project demonstrates my ability to design and deploy secure, automated cloud infrastructure using modern DevSecOps tooling.  
It highlights practical skills in Infrastructure-as-Code (IaC), Configuration Management, and Continuous Deployment — bridging the gap from hands-on system administration to scalable, automated engineering practices.  
The implementation showcases a production-ready foundation for hosting containerized web applications with security, availability, and maintainability in mind.

---

## Project Overview
- **Infrastructure:** AWS EC2 instance with a dedicated Elastic IP  
- **State Management:** Remote Terraform state stored in an encrypted S3 bucket with Versioning enabled  
- **Automation:** Modular Terraform design integrated with Ansible for post-provisioning configuration management  
- **Security (Access):** Implements Principle of Least Privilege (PoLP) with a dedicated IAM user and GitHub Secrets for all credentials  
- **Resilience:** Container is forced to recreate and reload content on every push, ensuring the website content is always current  

---

## Technical Stack
| Area | Tools |
|------|--------|
| Infrastructure as Code | Terraform (IaC, Remote State) |
| Configuration Management | Ansible (Playbooks, Handlers for Reload) |
| CI/CD Orchestration | GitHub Actions (End-to-End Automation, Secrets) |
| Cloud Platform | AWS (EC2, EIP, S3, IAM) |
| Containers | Docker and NGINX |
| Operating System | Ubuntu 24.04 LTS |

---

## Deployment Workflow
1. **Authentication:** GitHub Actions securely retrieves IAM and SSH Private Keys from repository secrets.  
2. **Terraform Apply (IaC):** Terraform validates the infrastructure against the remote S3 state file and ensures the EC2, EIP, and Security Group are correctly configured.  
3. **Ansible Execution:** Ansible connects via SSH to the live EC2 instance.  
4. **Configuration Management:** Ansible installs Docker, copies the updated `index.html` content, and uses a Handler to restart the NGINX container immediately.  
5. **Continuous Deployment:** The website is automatically updated within minutes, eliminating manual configuration or downtime.  

---

## Future Enhancements
- **PoLP Refinement:** Implement an IAM Instance Profile (Role) for the EC2 instance to eliminate permanent secrets from the host.  
- **State Locking:** Integrate a DynamoDB table for Terraform state locking to prevent concurrent updates.  
- **Monitoring:** Add CISSP-aligned security logging and monitoring via CloudWatch or an external SIEM solution.  
- **Expansion:** Transition the application deployment to a Docker Compose manifest managed entirely by Ansible.  

---

## Author
**Shaylee Czech**  
Cloud and Security Engineering Professional | CISSP Candidate  
[LinkedIn](https://www.linkedin.com/in/shayleeczech) | [GitHub](https://github.com/shayczech)
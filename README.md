# Terraform-Deployed Secure DevSecOps CI/CD Pipeline

This project demonstrates a secure, multi-container web application deployment, automated end-to-end with a DevSecOps CI/CD pipeline.

It highlights practical skills in Infrastructure-as-Code (IaC), Configuration Management, and Continuous Deployment, all orchestrated by GitHub Actions.

The architecture evolved from a single static container to a **dynamic two-container application** (a Node.js API and an Nginx reverse proxy), which fetches and displays real-time statistics from the GitHub API.

## Project Overview

* **Infrastructure:** AWS EC2 instance with a dedicated Elastic IP.
* **State Management:** Remote Terraform state stored in an encrypted S3 bucket with Versioning enabled.
* **Architecture:** A **two-container Docker application** using `network_mode: "host"`.
    * `portfolio-web`: An Nginx container acting as the web server and a **secure reverse proxy** (SSL termination).
    * `stats-api`: A Node.js/Express container that fetches data from the GitHub API and serves it on a local port (`3000`).
* **Functionality:** The frontend (`index.html`) makes a secure, relative API call to `/api/stats`. Nginx proxies this request internally to the Node.js container, which returns dynamic data. The site also includes a new **GRC Compliance Dashboard** for compliance mapping.
* **Security:** Implements Principle of Least Privilege (PoLP) via an IAM Instance Profile explicitly scope-limited for DNS updates (Certbot/Route 53). The CI/CD pipeline includes **Snyk** (SAST) and **Trivy** (Container Scanning) to shift-left vulnerability management, and enforces policy-as-code checks. Uses Certbot for automated SSL certificate acquisition.

## Technical Stack

| **Area** | **Tools** |
| :--- | :--- |
| Infrastructure as Code | Terraform (IaC, Remote State, IAM Roles) |
| Configuration Management | Ansible (Playbooks, Handlers) |
| CI/CD Orchestration | GitHub Actions (End-to-End Automation, Secrets) |
| Cloud Platform | AWS (EC2, EIP, S3, **IAM Instance Profiles**, Route 53) |
| Containers | **NGINX (Web/Proxy) & Node.js/Express (API)** |
| Operating System | Ubuntu 24.04 LTS |
| Security | Certbot (SSL), **Snyk (SAST)**, **Trivy (Container Scanning)**, UFW (Host Firewall), AWS IAM, GitHub Secrets, **Policy-as-Code (PaC)** |

## Deployment Workflow

1.  **Authentication:** GitHub Actions securely retrieves IAM and SSH Private Keys from repository secrets.
2.  **Security Scan (SAST):** **Snyk runs against Node.js dependencies, failing the build on High/Critical vulnerabilities.**
3.  **Terraform Apply (IaC):** Terraform validates infrastructure, ensuring the EC2 is provisioned with the correct IAM Instance Profile attached for PoLP.
4.  **Ansible Execution:** Ansible connects via SSH to the live EC2 instance.
5.  **Host Hardening & PaC:**
    * **Ansible installs all OS patches and sets up a secure baseline (e.g., UFW).**
    * **A simulated PyLint task enforces Policy-as-Code checks before deployment.**
6.  **API Deployment (Backend):**
    * Ansible copies the Node.js API source code and dependencies (including vulnerability patches in the Dockerfile).
    * Ansible builds the `stats-api:latest` Docker image.
    * **Trivy scans the image, using a `.trivyignore` file, and fails the deployment if un-ignored High/Critical vulnerabilities are found.**
    * Ansible starts the `stats-api` container, exposing it on `localhost:3000`.
    * An Ansible task actively verifies the API is responsive on `localhost:3000` before proceeding.
7.  **Web Deployment (Frontend):**
    * Certbot runs using the attached IAM Role (PoLP) to renew/acquire the SSL certificate via Route 53 DNS validation.
    * Ansible copies the static content (including `index.html`, `resume.html`, and `grc.html`).
    * Ansible starts the `portfolio-web` (Nginx) container, which proxies API requests and serves static content.
8.  **Live:** The frontend loads, securely fetches dynamic stats from its own `/api/stats` endpoint, and displays real-time GitHub data.

## Future Enhancements

* **State Locking:** Integrate a DynamoDB table for Terraform state locking to prevent concurrent updates.
* **Monitoring & Logging:** Add CISSP-aligned security logging and monitoring via CloudWatch or an external SIEM solution.
* **Expansion:** Transition the application deployment to a Docker Compose manifest managed entirely by Ansible.

## Author

**Shaylee Czech** Cloud and Security Engineering Professional | CISSP Candidate
[LinkedIn](https://www.linkedin.com/in/shayleeczech) | [GitHub](https://github.com/shayczech)
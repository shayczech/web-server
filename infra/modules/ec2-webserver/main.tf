# ------------------------------------------------------------------------------
# EC2 web server module: IAM, security group, instance, and Elastic IP
# ------------------------------------------------------------------------------

provider "aws" {
  region = "us-east-2"
}

# --- IAM: Certbot (Route 53 DNS validation for SSL) ---
resource "aws_iam_policy" "certbot_policy" {
  name        = "${var.server_name}-CertbotPolicy"
  description = "Allows Certbot to create and delete DNS records in Route 53 for certificate validation."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:GetChange",
          "route53:ListHostedZones",
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "ec2_certbot_role" {
  name               = "${var.server_name}-EC2CertbotRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "certbot_attach" {
  role       = aws_iam_role.ec2_certbot_role.name
  policy_arn = aws_iam_policy.certbot_policy.arn
}

# --- IAM: Managed policies for EC2 (CloudWatch Agent, SSM) ---
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_attach" {
  role       = aws_iam_role.ec2_certbot_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ssm_agent_attach" {
  role       = aws_iam_role.ec2_certbot_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.server_name}-EC2Profile"
  role = aws_iam_role.ec2_certbot_role.name
}

# --- Security group: SSH, HTTP, HTTPS, and port 81 ---
resource "aws_security_group" "allow_web" {
  name        = "${var.server_name}-sg"
  description = "Allow SSH, HTTP, HTTPS, and port 81 inbound."

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Port 81"
    from_port   = 81
    to_port     = 81
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.server_name}-sg"
  }
}

# --- Elastic IP (static public IP) ---
resource "aws_eip" "web_ip" {
  tags = {
    Name = "${var.server_name}-eip"
  }
}

resource "aws_eip_association" "web_ip_assoc" {
  instance_id   = aws_instance.app_server.id
  allocation_id = aws_eip.web_ip.allocation_id
}

# --- Delay after EIP association so network is stable before Ansible runs ---
resource "time_sleep" "wait_for_network" {
  depends_on      = [aws_eip_association.web_ip_assoc]
  create_duration = "60s"
}

# --- EC2 instance ---
resource "aws_instance" "app_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  tags = {
    Name = var.server_name
  }
}


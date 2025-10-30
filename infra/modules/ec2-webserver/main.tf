provider "aws" {
  region = "us-east-2" # <<< MUST MATCH YOUR CONFIGURED REGION
}

# --- NEW 1: IAM Policy for Route 53 (Certbot) ---
resource "aws_iam_policy" "certbot_policy" {
  name        = "${var.server_name}-CertbotPolicy"
  description = "Allows Certbot to create and delete DNS records in Route 53 for validation."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:GetChange",
          "route53:ListHostedZones",
          "route53:ChangeResourceRecordSets", # The main action Certbot needs
          "route53:ListResourceRecordSets"
        ]
        Resource = "*"
      },
    ]
  })
}

# --- NEW 2: IAM Role for the EC2 Instance ---
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

# --- NEW 3: Attach the Policy to the Role ---
resource "aws_iam_role_policy_attachment" "certbot_attach" {
  role       = aws_iam_role.ec2_certbot_role.name
  policy_arn = aws_iam_policy.certbot_policy.arn
}

# --- NEW: Attach CloudWatch Agent Policy for Logging ---
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_attach" {
  role       = aws_iam_role.ec2_certbot_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# --- NEW: Attach SSM Policy for keyless Ansible ---
resource "aws_iam_role_policy_attachment" "ssm_agent_attach" {
  role       = aws_iam_role.ec2_certbot_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# --- NEW 5: IAM Instance Profile (Links Role to EC2) ---
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.server_name}-EC2Profile"
  role = aws_iam_role.ec2_certbot_role.name
}

# 1. Define the Security Group (The Firewall)
# This now opens SSH (port 22) AND HTTP (port 80)
resource "aws_security_group" "allow_web" {
  name        = "${var.server_name}-sg"
  description = "Allow HTTP and SSH inbound traffic"

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open to the world
  }
  ingress {
    description = "NPM Admin Port 81"
    from_port   = 81
    to_port     = 81
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # This means "allow all outbound traffic"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.server_name}-sg"
  }
}

# 2. Allocate a new static (Elastic) IP address
resource "aws_eip" "web_ip" {
  tags = {
    Name = "${var.server_name}-eip"
  }
}

# 3. Associate the Elastic IP with the EC2 Instance
# This resource explicitly links the IP to the server.
resource "aws_eip_association" "web_ip_assoc" {
  instance_id   = aws_instance.app_server.id
  allocation_id = aws_eip.web_ip.allocation_id
}

# 4. Add an explicit delay after EIP association before instance provisioners run
# NOTE: Keeping this delay can be helpful even without provisioners, 
# as it gives the network time to stabilize before Ansible connects externally.
resource "time_sleep" "wait_for_network" {
  depends_on      = [aws_eip_association.web_ip_assoc]
  create_duration = "60s" # Wait 30 seconds
}

# 5. Define the EC2 Instance (The Server)
resource "aws_instance" "app_server" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  tags = {
    Name = var.server_name
  }
}


provider "aws" {
  region = "us-east-2" # <<< MUST MATCH YOUR CONFIGURED REGION
}
# 1. Define the Security Group (The Firewall)
# This now opens SSH (port 22) AND HTTP (port 80)
resource "aws_security_group" "allow_web" {
  name        = "${var.server_name}-sg"
  description = "Allow HTTP and SSH inbound traffic"

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: Open to the world. Good for testing.
  }
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

  tags = {
    Name = var.server_name
  }
}


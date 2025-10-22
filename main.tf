# 1. Configure the AWS Provider (you've already done this)
provider "aws" {
  region = "us-east-2" # Or your preferred region
}


# This configures the local provider (no settings needed)
provider "local" {}

# 2. Generate a new 2048-bit RSA private key
resource "tls_private_key" "my_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# 3. Creates a new key pair in AWS, using the public key we just generated
resource "aws_key_pair" "my_aws_key" {
  key_name   = "my-terraform-generated-key" # This is the name AWS will see
  public_key = tls_private_key.my_key.public_key_openssh
}

# 4. Saves the private key (that matches the public key) to your local disk
resource "local_file" "my_private_key" {
  content  = tls_private_key.my_key.private_key_pem
  filename = "my-terraform-key.pem" # This is the file it will create
  # This sets the permissions to -rw------- (read/write for owner only)
  file_permission = "0600"
}

# 2. NEW: Define the Security Group (The Firewall)
# This will allow SSH traffic (port 22) from any IP address.
resource "aws_security_group" "allow_ssh" {
  name        = "allow-ssh-sg"
  description = "Allow SSH inbound traffic"

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # This means "from any IP address"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # This means "allow all outbound traffic"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh_sg"
  }
}

# 3. Define the EC2 Instance (The Server)
# We will use a free "Amazon Linux 2" AMI
resource "aws_instance" "app_server" {
  ami           = "ami-0cfde0ea8edd312d4" # This is a common Amazon Linux 2 AMI in us-east-1
  instance_type = "t2.micro"              # Free-tier eligible

  # This connects the instance to the security group
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  # --- ADD THIS LINE ---
  # It tells AWS to allow SSH access using the key you just created.
  # Make sure "terraform-key" EXACTLY matches the name you gave the key in AWS.
  key_name = "my-terraform-generated-key"

  tags = {
    Name = "web-server"
  }
}
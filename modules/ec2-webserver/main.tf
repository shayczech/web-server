# 5. Define the Security Group (The Firewall)
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

# 6. Allocate a new static (Elastic) IP address
resource "aws_eip" "web_ip" {
  tags = {
    Name = "${var.server_name}-eip"
  }
}

# 7. Define the EC2 Instance (The Server)
resource "aws_instance" "app_server" {
  #Variables from variables.tf
  ami           = var.ami_id
  instance_type = var.instance_type

  # This connects the instance to the security group
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  #This specifies which key to use
  key_name = var.key_name

  tags = {
    Name = var.server_name
  }

  # --- Connection Info for Provisioners ---
  connection {
    type        = "ssh"
    user        = "ubuntu" # We know this is an Ubuntu server
    private_key = var.private_key_pem
    host        = aws_eip.web_ip.public_ip
  }

  # --- File Provisioner ---
  # Copies your local index.html to the server
  provisioner "file" {
    source      = var.index_html_path
    destination = "/tmp/index.html" # Temporary location on the server
  }
  # --- Remote-Exec Provisioner ---
  # Installs Docker, copies index.html into place, runs Nginx container
  provisioner "remote-exec" {
    inline = [
      # Standard Docker Install Steps (Same as before)
      "sudo apt-get update -y",
      "sudo apt-get install -y ca-certificates curl gnupg",
      "sudo install -m 0755 -d /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg",
      "sudo chmod a+r /etc/apt/keyrings/docker.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get update -y",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
      "sudo usermod -aG docker ubuntu",

      # NEW: Prepare directory for custom content
      "sudo mkdir -p /app/html", # Create a directory to hold our web content
      "sudo mv /tmp/index.html /app/html/index.html", # Move the uploaded file into place
      "sudo chown -R ubuntu:ubuntu /app", # Ensure correct ownership (optional but good practice)

      # Stop/Remove existing container if it exists (for idempotency on re-provisioning)
      "sudo docker stop my-nginx || true", # Ignore error if container doesn't exist
      "sudo docker rm my-nginx || true",   # Ignore error if container doesn't exist

      # Run Nginx container with Volume Mount
      # -v /app/html:/usr/share/nginx/html:ro mounts our custom content into the container's web root (read-only)
      "sudo docker run --name my-nginx -d -p 80:80 -v /app/html:/usr/share/nginx/html:ro nginx:latest"
    ]
  }
}

# 8. Associate the Elastic IP with the EC2 Instance
# This resource explicitly links the IP to the server.
resource "aws_eip_association" "web_ip_assoc" {
  instance_id   = aws_instance.app_server.id
  allocation_id = aws_eip.web_ip.allocation_id
}
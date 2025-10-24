
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

  user_data = <<EOF
#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
set -euxo pipefail

echo "===== [$(date)] Starting NGINX Proxy Manager setup ====="

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Create directories
mkdir -p /app/data
mkdir -p /app/html
echo "<h1>Hello from HTTPS-secured NGINX!</h1>" > /app/html/index.html

# Stop and remove any old containers
docker stop nginx-proxy-manager || true
docker rm nginx-proxy-manager || true
docker network create proxy_net || true

# Run NGINX Proxy Manager container
docker run -d \
  --name nginx-proxy-manager \
  --restart unless-stopped \
  -p 80:80 \
  -p 81:81 \
  -p 443:443 \
  -v /app/data:/data \
  -v /app/html:/var/www/html:ro \
  jc21/nginx-proxy-manager:latest

echo "===== [$(date)] NGINX Proxy Manager launched ====="
EOF


  tags = {
    Name = var.server_name
  }

  # --- Connection Info for Provisioners - RE-ADDED ---
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = var.private_key_pem
    host        = aws_eip.web_ip.public_ip # Connect via the EIP
    timeout     = "5m"
  }

  # --- File Provisioner - RE-ADDED ---
  provisioner "file" {
    source      = var.index_html_path
    destination = "/tmp/index.html"
    on_failure = continue
  }
/*
  # --- Remote-Exec Provisioner - RE-ADDED ---
  provisioner "remote-exec" {
    inline = [
      # Standard Docker Install Steps
      "sudo apt-get update -y",
      "sudo apt-get install -y ca-certificates curl gnupg",
      "sudo install -m 0755 -d /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg",
      "sudo chmod a+r /etc/apt/keyrings/docker.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get update -y",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
      "sudo usermod -aG docker ubuntu",

      # Prepare directory for custom content
      "sudo mkdir -p /app/html",
      "sudo mv /tmp/index.html /app/html/index.html",
      "sudo chown -R ubuntu:ubuntu /app",

      # Stop/Remove existing container if it exists
      "sudo docker stop my-nginx || true",
      "sudo docker rm my-nginx || true",

      # Run Nginx container with Volume Mount
      "sudo docker run --name my-nginx -d -p 80:80 -v /app/html:/usr/share/nginx/html:ro nginx:latest"
    ]
  }
  */
}


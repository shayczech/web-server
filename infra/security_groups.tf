# ------------------------------------------------------------------------------
# Security Groups: ALB (internet-facing) and EC2 (ALB-only ingress)
# ------------------------------------------------------------------------------

# --- ALB security group: accepts HTTP and HTTPS from internet ---
resource "aws_security_group" "alb" {
  name        = "${var.server_name}-alb-sg"
  description = "Allow HTTP and HTTPS inbound from internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.server_name}-alb-sg" }
}

# --- EC2 security group: accepts HTTP only from the ALB security group ---
# No port 443 on EC2 — ALB terminates SSL, forwards HTTP to EC2 on port 80.
# No SSH from internet — EC2s in private subnets; use SSM Session Manager.
resource "aws_security_group" "ec2" {
  name        = "${var.server_name}-ec2-sg"
  description = "Allow HTTP from ALB only; no direct internet access"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.server_name}-ec2-sg" }
}

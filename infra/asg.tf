# ------------------------------------------------------------------------------
# IAM, Launch Template, and Auto Scaling Group
# ------------------------------------------------------------------------------

# --- IAM Role for EC2 (CloudWatch Agent + SSM; ALB handles SSL) ---
resource "aws_iam_role" "ec2_role" {
  name = "${var.server_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Allow stats API to read IaC resource count (written by pipeline)
resource "aws_iam_role_policy" "ec2_ssm_iac_count" {
  name   = "${var.server_name}-ec2-ssm-iac-count"
  role   = aws_iam_role.ec2_role.id
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "ssm:GetParameter"
      Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/web-server/iac-resource-count"
    }]
  })
}

# Allow userdata/stats API to read GitHub token from SSM (avoids unauthenticated rate limit)
resource "aws_iam_role_policy" "ec2_ssm_github_token" {
  name   = "${var.server_name}-ec2-ssm-github-token"
  role   = aws_iam_role.ec2_role.id
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "ssm:GetParameter"
      Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/web-server/github-token"
    }]
  })
}

data "aws_caller_identity" "current" {}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.server_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# --- Launch Template ---
resource "aws_launch_template" "web" {
  name_prefix   = "${var.server_name}-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.ec2.id]
  }

  user_data = base64encode(file("${path.module}/userdata.sh"))

  lifecycle {
    create_before_destroy = true
  }

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.server_name}-asg-instance" }
  }
}

# --- Auto Scaling Group ---
# desired_capacity = 1 keeps cost low; only ASG "web-server-asg" is managed here.
resource "aws_autoscaling_group" "web" {
  name                = "${var.server_name}-asg"
  desired_capacity    = 1
  min_size            = 1
  max_size            = 4
  force_delete        = true
  vpc_zone_identifier = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  target_group_arns   = [aws_lb_target_group.web.arn]

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 300

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.server_name}-asg-instance"
    propagate_at_launch = true
  }

  depends_on = [aws_lb_listener.https]
}

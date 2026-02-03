# ═══════════════════════════════════════════════════════════════════════════════
# Lab 1a: Application Load Balancer (ALB) for EC2 Application
# ═══════════════════════════════════════════════════════════════════════════════
# Purpose: Create ALB infrastructure required by Lab 2 (CloudFront + WAF)

# Security Group for ALB
resource "aws_security_group" "chrisbarm_alb_sg01" {
  name        = "chrisbarm-alb-sg01"
  description = "Security group for Chrisbarm ALB - allows HTTP/HTTPS traffic"
  vpc_id      = aws_vpc.chrisbarm_vpc01.id

  tags = {
    Name = "chrisbarm-alb-sg01"
  }
}


# Allow outbound to EC2 security group (port 80 for application)
resource "aws_security_group_rule" "chrisbarm_alb_egress_to_ec2_01" {
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.chrisbarm_ec2_sg01.id
  security_group_id        = aws_security_group.chrisbarm_alb_sg01.id
}

# Update EC2 security group to allow inbound from ALB on port 80
resource "aws_security_group_rule" "chrisbarm_ec2_ingress_from_alb01" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.chrisbarm_alb_sg01.id
  security_group_id        = aws_security_group.chrisbarm_ec2_sg01.id
}

# Create the Application Load Balancer
resource "aws_lb" "chrisbarm_alb01" {
  name               = "chrisbarm-alb01"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.chrisbarm_alb_sg01.id]
  subnets            = aws_subnet.chrisbarm_public_subnets[*].id

  enable_deletion_protection = false

  tags = {
    Name = "chrisbarm-alb01"
  }
}

# Create Target Group for ALB
resource "aws_lb_target_group" "chrisbarm_tg01" {
  name        = "chrisbarm-tg01"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.chrisbarm_vpc01.id
  target_type = "instance"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200-299"
  }

  tags = {
    Name = "chrisbarm-tg01"
  }
}

# Register EC2 instance as target
resource "aws_lb_target_group_attachment" "chrisbarm_ec2_attachment01" {
  target_group_arn = aws_lb_target_group.chrisbarm_tg01.arn
  target_id        = aws_instance.chrisbarm_ec2_01.id
  port             = 80
}

# HTTP Listener - redirect to HTTPS
resource "aws_lb_listener" "chrisbarm_http_listener01" {
  load_balancer_arn = aws_lb.chrisbarm_alb01.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS Listener - required for CloudFront origin HTTPS
resource "aws_lb_listener" "chrisbarm_https_listener01" {
  load_balancer_arn = aws_lb.chrisbarm_alb01.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.chrisbarm_cert01.arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Forbidden"
      status_code  = "403"
    }
  }

  depends_on = [aws_acm_certificate_validation.chrisbarm_cert_validation01]
}

# ═══════════════════════════════════════════════════════════════════════════════
# Outputs
# ═══════════════════════════════════════════════════════════════════════════════

output "chrisbarm_alb_dns_name01" {
  description = "DNS name of the load balancer"
  value       = aws_lb.chrisbarm_alb01.dns_name
}

output "chrisbarm_alb_arn01" {
  description = "ARN of the load balancer"
  value       = aws_lb.chrisbarm_alb01.arn
}

output "chrisbarm_target_group_arn01" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.chrisbarm_tg01.arn
}

output "chrisbarm_http_listener_arn01" {
  description = "ARN of HTTP listener"
  value       = aws_lb_listener.chrisbarm_http_listener01.arn
}

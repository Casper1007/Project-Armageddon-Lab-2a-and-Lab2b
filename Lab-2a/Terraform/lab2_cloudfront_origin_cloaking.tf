data "aws_ec2_managed_prefix_list" "chrisbarm_cf_origin_facing01" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_security_group_rule" "chrisbarm_alb_ingress_cf44301" {
  type              = "ingress"
  security_group_id = aws_security_group.chrisbarm_alb_sg01.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"

  prefix_list_ids = [
    data.aws_ec2_managed_prefix_list.chrisbarm_cf_origin_facing01.id
  ]
}

resource "random_password" "chrisbarm_origin_header_value01" {
  length  = 32
  special = false
}

resource "aws_lb_listener_rule" "chrisbarm_require_origin_header01" {
  listener_arn = aws_lb_listener.chrisbarm_https_listener01.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.chrisbarm_tg01.arn
  }

  condition {
    http_header {
      http_header_name = "X-Chewbacca-Growl"
      values           = [random_password.chrisbarm_origin_header_value01.result]
    }
  }
}

resource "aws_lb_listener_rule" "chrisbarm_default_block01" {
  listener_arn = aws_lb_listener.chrisbarm_https_listener01.arn
  priority     = 100

  action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Forbidden"
      status_code  = "403"
    }
  }

  condition {
    path_pattern { values = ["*"] }
  }
}

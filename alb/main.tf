resource "aws_lb" "create_alb" {
  name                        = var.alb_configs.name
  internal                    = var.alb_configs.internal
  load_balancer_type          = var.alb_configs.load_balancer_type
  security_groups             = var.alb_configs.security_groups
  subnets                     = var.alb_configs.subnets
  idle_timeout                = var.alb_configs.idle_timeout
  enable_deletion_protection  = var.alb_configs.enable_deletion_protection

  access_logs {
      bucket                  = var.alb_configs.access_logs_bucket
      enabled                 = var.alb_configs.access_logs_enabled
  }
  tags                        = var.alb_configs.tags
}

resource "aws_wafv2_web_acl_association" "alb_waf_association" {
  count                       = var.alb_configs.waf_enable ? 1 : 0
  resource_arn                = aws_lb.create_alb.arn
  web_acl_arn                 = var.alb_configs.waf_acl_arn
}

resource "aws_lb_target_group" "create_target_group" {
  count            = var.target_group_configs.new_target_group ? 1 : 0
  name                = var.target_group_configs.name
  port                = var.target_group_configs.port
  protocol            = var.target_group_configs.protocol
  vpc_id              = var.target_group_configs.vpc_id

  stickiness {
    type              = var.target_group_configs.stickiness_type
    cookie_duration   = var.target_group_configs.stickiness_cookie_duration
  }
}
resource "aws_lb_target_group_attachment" "target_attachment" {
  count            = var.target_group_configs.new_target_group ? 1 : 0
  target_group_arn = aws_lb_target_group.create_target_group[0].arn
  target_id        = var.target_group_configs.target_id
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.create_alb.arn
  port              = 80
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

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.create_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.https_listener_configs.ssl_policy
  certificate_arn   = var.https_listener_configs.app-a_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = var.target_group_configs.new_target_group ? aws_lb_target_group.create_target_group[0].arn : var.http_listener_configs.default_action_target_group_arn
  }
}

# Below part is to add the app-b certificate in the SNI
resource "aws_lb_listener_certificate" "sni_certificate" {
  count             = var.https_listener_configs.is_addon_certificate_arn ? 1 : 0
  listener_arn      = aws_lb_listener.https_listener.arn
  certificate_arn   = var.https_listener_configs.addon_certificate_arn
}


resource "aws_lb_listener_rule" "app-a_https" {
  listener_arn = aws_lb_listener.https_listener.arn
  priority     = var.alb_rules.app-a_rule_priority

  action {
    type             = "forward"
    target_group_arn = var.alb_rules.app-a_target_group_arn
  }

  condition {
    host_header {
      values = var.alb_rules.domains_list
    }
  }
  condition {
    http_header {
      http_header_name = "test"
      values           = [true]
    }
  }
}

resource "aws_lb_listener_rule" "app-a_redirect_http_to_https" {
  listener_arn = aws_lb_listener.http_listener.arn
  priority     = var.alb_rules.app-a_rule_priority
  action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    host_header {
      values = var.alb_rules.domains_list
    }
  }
  condition {
    http_header {
      http_header_name = "test"
      values           = [true]
    }
  }
}


resource "aws_lb_listener_rule" "app-b-https" {
  listener_arn = aws_lb_listener.https_listener.arn
  priority     = var.alb_rules.app-b-rule_priority

  action {
    type             = "forward"
    target_group_arn = var.alb_rules.app-b-target_group_arn
  }

  condition {
    path_pattern {
      values = ["/app-b/*"]
    }
  }

  condition {
    host_header {
      values = var.alb_rules.domains_list
    }
  }
}

resource "aws_lb_listener_rule" "app-b-redirect_http_to_https" {
  listener_arn = aws_lb_listener.http_listener.arn
  priority     = var.alb_rules.app-b-rule_priority
  action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    path_pattern {
      values = ["/app-b/*"]
    }
  }

  condition {
    host_header {
      values = var.alb_rules.domains_list
    }
  }
}

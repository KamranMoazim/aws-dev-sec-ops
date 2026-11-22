locals {
  blue_green          = var.deployment_strategy == "BLUE_GREEN"
  production_listener = local.https_enabled ? aws_lb_listener.https[0].arn : aws_lb_listener.http.arn
  listener_protocol   = local.https_enabled ? "HTTPS" : "HTTP"
}

resource "aws_lb_target_group" "green" {
  #checkov:skip=CKV_AWS_378:TLS terminates at the ALB; ALB to task traffic stays in private subnets
  count = local.blue_green ? 1 : 0

  name                 = "${var.name}-green"
  port                 = var.container_port
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = 30

  health_check {
    path                = var.health_check_path
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

# ECS shifts the weights during a deployment; Terraform only creates the rules.
resource "aws_lb_listener_rule" "production" {
  count = local.blue_green ? 1 : 0

  listener_arn = local.production_listener
  priority     = 1

  action {
    type = "forward"

    forward {
      target_group {
        arn    = aws_lb_target_group.this.arn
        weight = 100
      }

      target_group {
        arn    = aws_lb_target_group.green[0].arn
        weight = 0
      }
    }
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  lifecycle {
    ignore_changes = [action]
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_test" {
  for_each = local.blue_green ? toset(var.test_listener_cidrs) : toset([])

  security_group_id = aws_security_group.alb.id
  description       = "Blue/green test listener"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = var.test_listener_port
  to_port           = var.test_listener_port
}

resource "aws_lb_listener" "test" {
  #checkov:skip=CKV_AWS_2:Private test listener; uses HTTPS whenever a certificate is set
  #checkov:skip=CKV_AWS_103:TLS policy is set when the listener uses HTTPS
  count = local.blue_green ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = var.test_listener_port
  protocol          = local.listener_protocol
  ssl_policy        = local.https_enabled ? "ELBSecurityPolicy-TLS13-1-2-2021-06" : null
  certificate_arn   = local.https_enabled ? var.certificate_arn : null

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not found"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener_rule" "test" {
  count = local.blue_green ? 1 : 0

  listener_arn = aws_lb_listener.test[0].arn
  priority     = 1

  action {
    type = "forward"

    forward {
      target_group {
        arn    = aws_lb_target_group.this.arn
        weight = 100
      }

      target_group {
        arn    = aws_lb_target_group.green[0].arn
        weight = 0
      }
    }
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  lifecycle {
    ignore_changes = [action]
  }
}

data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "blue_green" {
  count = local.blue_green ? 1 : 0

  name               = "${local.full_name}-bluegreen"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy_attachment" "blue_green" {
  count = local.blue_green ? 1 : 0

  role       = aws_iam_role.blue_green[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECSInfrastructureRolePolicyForLoadBalancers"
}

terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

data "aws_region" "current" {}

locals {
  full_name = "${var.name}-${var.service_name}"
}

resource "aws_ecs_cluster" "this" {
  name = var.name

  setting {
    name  = "containerInsights"
    value = "enhanced"
  }
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.name}/${var.service_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
}

resource "aws_ecs_task_definition" "this" {
  family                   = local.full_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.cpu_architecture
  }

  container_definitions = jsonencode([
    {
      name                   = var.service_name
      image                  = var.image
      essential              = true
      readonlyRootFilesystem = true
      portMappings = [
        { containerPort = var.container_port, protocol = "tcp" }
      ]
      environment = [for key, value in var.environment : { name = key, value = value }]
      secrets     = [for key, value in var.secrets : { name = key, valueFrom = value }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app.name
          awslogs-region        = data.aws_region.current.region
          awslogs-stream-prefix = var.service_name
        }
      }
    }
  ])
}

resource "aws_ecs_service" "this" {
  name                              = var.service_name
  cluster                           = aws_ecs_cluster.this.id
  task_definition                   = aws_ecs_task_definition.this.arn
  desired_count                     = var.desired_count
  launch_type                       = "FARGATE"
  platform_version                  = "LATEST"
  health_check_grace_period_seconds = 30
  propagate_tags                    = "SERVICE"
  enable_ecs_managed_tags           = true
  wait_for_steady_state             = true

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  alarms {
    alarm_names = local.rollback_alarm_names
    enable      = true
    rollback    = true
  }

  dynamic "deployment_configuration" {
    for_each = local.blue_green ? [1] : []

    content {
      strategy             = "BLUE_GREEN"
      bake_time_in_minutes = var.bake_time_minutes
    }
  }

  network_configuration {
    subnets          = var.app_subnet_ids
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = var.service_name
    container_port   = var.container_port

    dynamic "advanced_configuration" {
      for_each = local.blue_green ? [1] : []

      content {
        alternate_target_group_arn = aws_lb_target_group.green[0].arn
        production_listener_rule   = aws_lb_listener_rule.production[0].arn
        test_listener_rule         = aws_lb_listener_rule.test[0].arn
        role_arn                   = aws_iam_role.blue_green[0].arn
      }
    }
  }

  # Blue/green swaps the primary and alternate target groups on every deployment.
  lifecycle {
    ignore_changes = [desired_count, load_balancer]
  }

  depends_on = [aws_lb_listener.http, aws_lb_listener.https, aws_iam_role_policy_attachment.blue_green]
}

resource "aws_appautoscaling_target" "this" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.min_count
  max_capacity       = var.max_count
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "${local.full_name}-cpu"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.this.service_namespace
  resource_id        = aws_appautoscaling_target.this.resource_id
  scalable_dimension = aws_appautoscaling_target.this.scalable_dimension

  target_tracking_scaling_policy_configuration {
    target_value       = var.cpu_target_percent
    scale_in_cooldown  = 120
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

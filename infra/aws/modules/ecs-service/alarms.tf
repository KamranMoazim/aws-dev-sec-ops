locals {
  target_groups = merge(
    { blue = aws_lb_target_group.this.arn_suffix },
    local.blue_green ? { green = aws_lb_target_group.green[0].arn_suffix } : {},
  )
  rollback_alarm_names = [
    aws_cloudwatch_metric_alarm.target_5xx.alarm_name,
    aws_cloudwatch_metric_alarm.unhealthy_hosts.alarm_name,
    aws_cloudwatch_metric_alarm.latency_p99.alarm_name,
  ]
}

resource "aws_cloudwatch_metric_alarm" "target_5xx" {
  alarm_name          = "${local.full_name}-target-5xx"
  alarm_description   = "Tasks returned 5xx responses; rolls back an in-flight deployment."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_5XX_Count"
  dimensions          = { LoadBalancer = aws_lb.this.arn_suffix }
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = var.error_5xx_threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${local.full_name}-unhealthy-hosts"
  alarm_description   = "A target group has unhealthy tasks; rolls back an in-flight deployment."
  evaluation_periods  = 2
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  metric_query {
    id          = "unhealthy"
    expression  = "MAX([${join(",", keys(local.target_groups))}])"
    label       = "Unhealthy tasks (max over target groups)"
    return_data = true
  }

  dynamic "metric_query" {
    for_each = local.target_groups

    content {
      id = metric_query.key

      metric {
        namespace   = "AWS/ApplicationELB"
        metric_name = "UnHealthyHostCount"
        period      = 60
        stat        = "Maximum"
        dimensions = {
          LoadBalancer = aws_lb.this.arn_suffix
          TargetGroup  = metric_query.value
        }
      }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "latency_p99" {
  alarm_name          = "${local.full_name}-latency-p99"
  alarm_description   = "p99 response time above target; rolls back an in-flight deployment."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "TargetResponseTime"
  dimensions          = { LoadBalancer = aws_lb.this.arn_suffix }
  extended_statistic  = "p99"
  period              = 60
  evaluation_periods  = 3
  threshold           = var.latency_p99_seconds
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions
}

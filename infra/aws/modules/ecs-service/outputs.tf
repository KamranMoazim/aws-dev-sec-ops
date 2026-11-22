output "url" {
  description = "Public URL of the service."
  value       = "${local.https_enabled ? "https" : "http"}://${aws_lb.this.dns_name}"
}

output "alb_dns_name" {
  description = "Load balancer DNS name."
  value       = aws_lb.this.dns_name
}

output "cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.this.name
}

output "service_name" {
  description = "ECS service name."
  value       = aws_ecs_service.this.name
}

output "app_security_group_id" {
  description = "Security group of the tasks."
  value       = aws_security_group.app.id
}

output "task_execution_role_arn" {
  description = "Task execution role."
  value       = aws_iam_role.execution.arn
}

output "log_group_name" {
  description = "App log group."
  value       = aws_cloudwatch_log_group.app.name
}

output "alb_zone_id" {
  description = "Load balancer hosted zone ID for alias records."
  value       = aws_lb.this.zone_id
}

output "alb_arn" {
  description = "Load balancer ARN, e.g. for a WAF association."
  value       = aws_lb.this.arn
}

output "alarm_names" {
  description = "Alarms that roll back an in-flight deployment."
  value       = local.rollback_alarm_names
}

output "alb_arn_suffix" {
  description = "Load balancer ARN suffix for CloudWatch dimensions."
  value       = aws_lb.this.arn_suffix
}

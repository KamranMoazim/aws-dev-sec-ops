output "vpc_id" {
  description = "VPC ID."
  value       = module.environment.vpc_id
}

output "kms_key_arn" {
  description = "Environment KMS key."
  value       = module.environment.kms_key_arn
}

output "app_url" {
  description = "Public URL of the service."
  value       = module.environment.app_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = module.environment.ecs_cluster_name
}

output "ecs_service_name" {
  description = "ECS service name."
  value       = module.environment.ecs_service_name
}

output "app_log_group" {
  description = "CloudWatch log group for the app."
  value       = module.environment.app_log_group
}

output "db_secret_arn" {
  description = "RDS-managed secret with the database credentials."
  value       = module.environment.db_secret_arn
}

output "image_tag_parameter" {
  description = "SSM parameter holding the released image tag."
  value       = module.environment.image_tag_parameter
}

output "dashboard_name" {
  description = "CloudWatch dashboard."
  value       = module.environment.dashboard_name
}

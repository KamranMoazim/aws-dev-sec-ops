output "vpc_id" {
  description = "Dev VPC ID."
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnets for the ALB."
  value       = module.network.public_subnet_ids
}

output "app_subnet_ids" {
  description = "Private subnets for ECS tasks."
  value       = module.network.app_subnet_ids
}

output "db_subnet_ids" {
  description = "Isolated subnets for RDS."
  value       = module.network.db_subnet_ids
}

output "kms_key_arn" {
  description = "Dev environment KMS key."
  value       = module.secrets.kms_key_arn
}

output "app_url" {
  description = "Public URL of the dev service."
  value       = local.dns_enabled ? "https://${local.app_fqdn}" : module.app.url
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = module.app.cluster_name
}

output "ecs_service_name" {
  description = "ECS service name."
  value       = module.app.service_name
}

output "app_log_group" {
  description = "CloudWatch log group for the app."
  value       = module.app.log_group_name
}

output "db_secret_arn" {
  description = "RDS-managed secret with the database credentials."
  value       = module.rds.master_user_secret_arn
}

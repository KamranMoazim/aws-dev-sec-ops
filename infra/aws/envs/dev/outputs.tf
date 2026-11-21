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

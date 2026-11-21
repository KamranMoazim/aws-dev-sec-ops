output "ecr_repository_url" {
  description = "Image repository URL."
  value       = module.ecr.repository_url
}

output "ecr_repository_arn" {
  description = "Image repository ARN."
  value       = module.ecr.repository_arn
}

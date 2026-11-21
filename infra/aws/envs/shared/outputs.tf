output "ecr_repository_url" {
  description = "Image repository URL."
  value       = module.ecr.repository_url
}

output "ecr_repository_arn" {
  description = "Image repository ARN."
  value       = module.ecr.repository_arn
}

output "dns_zone_name_servers" {
  description = "Add these as NS records for the subdomain at the registrar."
  value       = local.dns_enabled ? aws_route53_zone.this[0].name_servers : []
}

output "repository_name" {
  description = "Repository name."
  value       = aws_ecr_repository.this.name
}

output "repository_url" {
  description = "Repository URL for docker push/pull."
  value       = aws_ecr_repository.this.repository_url
}

output "repository_arn" {
  description = "Repository ARN."
  value       = aws_ecr_repository.this.arn
}

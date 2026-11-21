output "kms_key_arn" {
  description = "ARN of the environment KMS key."
  value       = aws_kms_key.this.arn
}

output "kms_key_alias" {
  description = "Alias of the environment KMS key."
  value       = aws_kms_alias.this.name
}

output "secret_arns" {
  description = "Secret ARNs keyed by short name."
  value       = { for key, secret in aws_secretsmanager_secret.this : key => secret.arn }
}

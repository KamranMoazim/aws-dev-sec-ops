output "state_bucket" {
  description = "S3 bucket holding Terraform state."
  value       = aws_s3_bucket.state.id
}

output "state_kms_key_arn" {
  description = "KMS key encrypting Terraform state."
  value       = aws_kms_key.state.arn
}

output "backend_config" {
  description = "Values for backend.hcl in each environment."
  value       = <<-EOT
    bucket       = "${aws_s3_bucket.state.id}"
    region       = "${var.region}"
    encrypt      = true
    kms_key_id   = "${aws_kms_key.state.arn}"
    use_lockfile = true
  EOT
}

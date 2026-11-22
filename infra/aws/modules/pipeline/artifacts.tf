module "artifacts" {
  source = "../artifact-bucket"

  name           = coalesce(var.artifact_bucket_name, "${var.name}-artifacts-${local.account_id}-${local.region}")
  kms_key_arn    = var.kms_key_arn
  retention_days = var.artifact_retention_days
}

moved {
  from = aws_s3_bucket.artifacts
  to   = module.artifacts.aws_s3_bucket.this
}

moved {
  from = aws_s3_bucket_versioning.artifacts
  to   = module.artifacts.aws_s3_bucket_versioning.this
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.artifacts
  to   = module.artifacts.aws_s3_bucket_server_side_encryption_configuration.this
}

moved {
  from = aws_s3_bucket_public_access_block.artifacts
  to   = module.artifacts.aws_s3_bucket_public_access_block.this
}

moved {
  from = aws_s3_bucket_ownership_controls.artifacts
  to   = module.artifacts.aws_s3_bucket_ownership_controls.this
}

moved {
  from = aws_s3_bucket_lifecycle_configuration.artifacts
  to   = module.artifacts.aws_s3_bucket_lifecycle_configuration.this
}

moved {
  from = aws_s3_bucket_policy.artifacts
  to   = module.artifacts.aws_s3_bucket_policy.this
}

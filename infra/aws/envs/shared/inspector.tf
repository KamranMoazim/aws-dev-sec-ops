resource "aws_inspector2_enabler" "ecr" {
  count = var.enable_inspector ? 1 : 0

  account_ids    = [data.aws_caller_identity.current.account_id]
  resource_types = ["ECR"]
}

# Registry scanning is account-wide; scope it to this project so other repos in the account are untouched.
resource "aws_ecr_registry_scanning_configuration" "this" {
  count = var.enable_inspector ? 1 : 0

  scan_type = "ENHANCED"

  rule {
    scan_frequency = "CONTINUOUS_SCAN"

    repository_filter {
      filter      = var.app_name
      filter_type = "WILDCARD"
    }
  }

  depends_on = [aws_inspector2_enabler.ecr]
}

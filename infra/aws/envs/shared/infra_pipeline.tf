data "aws_kms_alias" "state" {
  name = "alias/${var.project}-tfstate"
}

# Plans and applies workload environments after approval; bootstrap and this shared root stay manual.
module "infra_pipeline" {
  source = "../../modules/infra-pipeline"

  name               = "${var.project}-infra"
  project            = var.project
  connection_arn     = aws_codeconnections_connection.github.arn
  repository_id      = var.repository_id
  environments       = var.infra_pipeline_environments
  state_bucket       = "${var.project}-tfstate-${data.aws_caller_identity.current.account_id}-${local.region}"
  state_kms_key_arn  = data.aws_kms_alias.state.target_key_arn
  approval_topic_arn = aws_sns_topic.approvals.arn
  kms_key_arn        = module.shared_kms.kms_key_arn

  terraform_variables = merge(
    local.dns_enabled ? { dns_zone_name = var.dns_zone_name } : {},
    { alert_emails = jsonencode(var.alert_emails) },
  )
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  region = data.aws_region.current.region

  targets = {
    for env, settings in {
      dev     = { account_id = var.dev_account_id, hostname = "dev" }
      staging = { account_id = var.staging_account_id, hostname = "staging" }
      prod    = { account_id = var.prod_account_id, hostname = "app" }
      } : env => {
      account_id = coalesce(settings.account_id, data.aws_caller_identity.current.account_id)
      cluster    = "${var.project}-${env}"
      parameter  = "/${var.project}/${env}/${var.app_name}/image-tag"
      app_url    = local.dns_enabled ? "https://${settings.hostname}.${var.dns_zone_name}" : lookup(var.app_urls, env, "")
    }
  }

  environments = {
    for env, target in local.targets : env => {
      name                     = env
      cluster_name             = target.cluster
      service_name             = var.app_name
      service_arn              = "arn:aws:ecs:${local.region}:${target.account_id}:service/${target.cluster}/${var.app_name}"
      task_role_arns           = [for suffix in ["execution", "task"] : "arn:aws:iam::${target.account_id}:role/${target.cluster}-${var.app_name}-${suffix}"]
      app_url                  = target.app_url
      image_tag_parameter_name = target.parameter
      image_tag_parameter_arn  = "arn:aws:ssm:${local.region}:${target.account_id}:parameter${target.parameter}"
    }
  }
}

module "shared_kms" {
  source = "../../modules/secrets"

  name               = "${var.project}-shared"
  publisher_services = ["codestar-notifications.amazonaws.com"]
}

resource "aws_codeconnections_connection" "github" {
  name          = "${var.project}-github"
  provider_type = "GitHub"
}

module "app_pipeline" {
  source = "../../modules/pipeline"

  name               = "${var.project}-${var.app_name}"
  connection_arn     = aws_codeconnections_connection.github.arn
  repository_id      = var.repository_id
  branch             = "develop"
  ecr_repository_url = module.ecr.repository_url
  ecr_repository_arn = module.ecr.repository_arn
  container_name     = var.app_name
  kms_key_arn        = module.shared_kms.kms_key_arn
  environments       = [local.environments.dev]

  # Infra pipeline files would otherwise start an app deploy that races the Terraform apply.
  trigger_file_path_excludes = ["buildspecs/buildspec-infra-*", "scripts/ci/terraform-*"]
}

resource "aws_sns_topic" "approvals" {
  name              = "${var.project}-release-approvals"
  kms_master_key_id = module.shared_kms.kms_key_arn
}

resource "aws_sns_topic_subscription" "approvals" {
  for_each = toset(var.approval_emails)

  topic_arn = aws_sns_topic.approvals.arn
  protocol  = "email"
  endpoint  = each.value
}

# Builds once from release/*, then promotes that same image: staging (smoke + DAST) -> approval -> prod.
module "release_pipeline" {
  source = "../../modules/pipeline"

  name                 = "${var.project}-${var.app_name}-release"
  artifact_bucket_name = "${var.project}-release-artifacts-${data.aws_caller_identity.current.account_id}-${local.region}"
  connection_arn       = aws_codeconnections_connection.github.arn
  repository_id        = var.repository_id
  branch               = "main"
  trigger_branches     = ["release/*"]
  trigger_file_paths   = null
  ecr_repository_url   = module.ecr.repository_url
  ecr_repository_arn   = module.ecr.repository_arn
  container_name       = var.app_name
  kms_key_arn          = module.shared_kms.kms_key_arn
  approval_topic_arn   = aws_sns_topic.approvals.arn

  environments = [
    merge(local.environments.staging, { dast = true }),
    merge(local.environments.prod, { approval = true }),
  ]
}

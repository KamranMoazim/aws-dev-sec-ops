data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  region         = data.aws_region.current.region
  dev_account_id = coalesce(var.dev_account_id, data.aws_caller_identity.current.account_id)
  dev_name       = "${var.project}-dev"
  dev_parameter  = "/${var.project}/dev/${var.app_name}/image-tag"
  dev_app_url    = local.dns_enabled ? "https://dev.${var.dns_zone_name}" : var.dev_app_url
}

module "shared_kms" {
  source = "../../modules/secrets"

  name = "${var.project}-shared"
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

  dev = {
    cluster_name             = local.dev_name
    service_name             = var.app_name
    service_arn              = "arn:aws:ecs:${local.region}:${local.dev_account_id}:service/${local.dev_name}/${var.app_name}"
    task_role_arns           = [for suffix in ["execution", "task"] : "arn:aws:iam::${local.dev_account_id}:role/${local.dev_name}-${var.app_name}-${suffix}"]
    app_url                  = local.dev_app_url
    image_tag_parameter_name = local.dev_parameter
    image_tag_parameter_arn  = "arn:aws:ssm:${local.region}:${local.dev_account_id}:parameter${local.dev_parameter}"
  }
}

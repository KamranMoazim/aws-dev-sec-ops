terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 6.0"
      configuration_aliases = [aws.dns]
    }
  }
}

locals {
  name = "${var.project}-${var.environment}"
}

module "secrets" {
  source = "../secrets"

  name                        = local.name
  secret_recovery_window_days = var.secret_recovery_window_days
}

module "network" {
  source = "../network"

  name                    = local.name
  cidr_block              = var.vpc_cidr
  availability_zones      = var.availability_zones
  single_nat_gateway      = var.single_nat_gateway
  kms_key_arn             = module.secrets.kms_key_arn
  flow_log_retention_days = var.flow_log_retention_days
}

# The pipeline writes the released tag after a passing smoke test; Terraform follows it instead of reverting deploys.
resource "aws_ssm_parameter" "image_tag" {
  #checkov:skip=CKV2_AWS_34:Image tag is not sensitive
  name           = "/${var.project}/${var.environment}/${var.app_name}/image-tag"
  type           = "String"
  insecure_value = var.initial_image_tag

  lifecycle {
    ignore_changes = [insecure_value]
  }
}

data "aws_ecr_repository" "app" {
  name        = var.app_name
  registry_id = var.ecr_registry_id
}

module "rds" {
  source = "../rds"

  name                    = local.name
  vpc_id                  = module.network.vpc_id
  subnet_ids              = module.network.db_subnet_ids
  allowed_security_groups = { app = module.app.app_security_group_id }
  kms_key_arn             = module.secrets.kms_key_arn
  instance_class          = var.db_instance_class
  multi_az                = var.db_multi_az
  deletion_protection     = !var.teardown_friendly
  skip_final_snapshot     = var.teardown_friendly
  apply_immediately       = true
}

module "app" {
  source = "../ecs-service"

  name                    = local.name
  service_name            = var.app_name
  vpc_id                  = module.network.vpc_id
  vpc_cidr                = module.network.vpc_cidr_block
  public_subnet_ids       = module.network.public_subnet_ids
  app_subnet_ids          = module.network.app_subnet_ids
  image                   = "${data.aws_ecr_repository.app.repository_url}:${aws_ssm_parameter.image_tag.insecure_value}"
  kms_key_arn             = module.secrets.kms_key_arn
  enable_https            = local.dns_enabled
  certificate_arn         = local.dns_enabled ? aws_acm_certificate_validation.app[0].certificate_arn : null
  alb_deletion_protection = !var.teardown_friendly
  desired_count           = var.min_count
  min_count               = var.min_count
  max_count               = var.max_count
  deployment_strategy     = var.deployment_strategy
  bake_time_minutes       = var.bake_time_minutes
  test_listener_cidrs     = [module.network.vpc_cidr_block]

  environment = {
    DB_HOST = module.rds.address
    DB_PORT = tostring(module.rds.port)
    DB_NAME = module.rds.database_name
    DB_SSL  = "true"
  }

  secrets = {
    DB_USER     = "${module.rds.master_user_secret_arn}:username::"
    DB_PASSWORD = "${module.rds.master_user_secret_arn}:password::"
  }

  secret_arns = [module.rds.master_user_secret_arn]
}

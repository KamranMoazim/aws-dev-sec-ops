locals {
  name = "${var.project}-dev"
}

module "secrets" {
  source = "../../modules/secrets"

  name                        = local.name
  secret_recovery_window_days = var.secret_recovery_window_days
}

module "network" {
  source = "../../modules/network"

  name                    = local.name
  cidr_block              = var.vpc_cidr
  availability_zones      = var.availability_zones
  single_nat_gateway      = var.single_nat_gateway
  kms_key_arn             = module.secrets.kms_key_arn
  flow_log_retention_days = var.flow_log_retention_days
}

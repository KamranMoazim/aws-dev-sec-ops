module "environment" {
  source = "../../modules/app-environment"

  providers = {
    aws     = aws
    aws.dns = aws.dns
  }

  project                     = var.project
  environment                 = "dev"
  app_name                    = var.app_name
  hostname                    = "dev"
  dns_zone_name               = var.dns_zone_name
  ecr_registry_id             = var.ecr_registry_id
  initial_image_tag           = var.initial_image_tag
  vpc_cidr                    = var.vpc_cidr
  availability_zones          = var.availability_zones
  single_nat_gateway          = var.single_nat_gateway
  flow_log_retention_days     = var.flow_log_retention_days
  secret_recovery_window_days = var.secret_recovery_window_days
  db_instance_class           = var.db_instance_class
  teardown_friendly           = var.teardown_friendly
}

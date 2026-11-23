module "environment" {
  source = "../../modules/app-environment"

  providers = {
    aws     = aws
    aws.dns = aws.dns
  }

  project                     = var.project
  environment                 = "prod"
  app_name                    = var.app_name
  hostname                    = "app"
  dns_zone_name               = var.dns_zone_name
  ecr_registry_id             = var.ecr_registry_id
  initial_image_tag           = var.initial_image_tag
  vpc_cidr                    = var.vpc_cidr
  availability_zones          = var.availability_zones
  single_nat_gateway          = var.single_nat_gateway
  flow_log_retention_days     = var.flow_log_retention_days
  secret_recovery_window_days = var.secret_recovery_window_days
  db_instance_class           = var.db_instance_class
  db_multi_az                 = true
  min_count                   = 2
  max_count                   = 4
  deployment_strategy         = "BLUE_GREEN"
  bake_time_minutes           = 10
  enable_waf                  = true
  teardown_friendly           = var.teardown_friendly
  alert_emails                = var.alert_emails
}

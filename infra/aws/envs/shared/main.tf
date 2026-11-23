module "ecr" {
  source = "../../modules/ecr"

  name             = var.app_name
  pull_account_ids = var.workload_account_ids
  force_delete     = var.ecr_force_delete
}

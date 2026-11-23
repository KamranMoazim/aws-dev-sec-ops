module "baseline" {
  source = "../../modules/security-baseline"

  project            = var.project
  alert_emails       = var.alert_emails
  force_destroy_logs = var.force_destroy_logs
}

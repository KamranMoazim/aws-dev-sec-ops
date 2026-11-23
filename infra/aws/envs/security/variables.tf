variable "project" {
  description = "Short project name used in resource names."
  type        = string
  default     = "devsecops"
}

variable "region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "deploy_role_arn" {
  description = "Role to assume in the security account. null uses the caller's credentials (single-account mode)."
  type        = string
  default     = null
}

variable "alert_emails" {
  description = "Emails for high and critical findings. Set via TF_VAR_alert_emails."
  type        = list(string)
  default     = []
}

variable "force_destroy_logs" {
  description = "Allow destroying the audit log bucket with objects in it (demo teardown)."
  type        = bool
  default     = false
}

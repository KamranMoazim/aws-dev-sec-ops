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
  description = "Role to assume in the target account. null uses the caller's credentials (single-account mode)."
  type        = string
  default     = null
}

variable "app_name" {
  description = "Application / ECR repository name."
  type        = string
  default     = "hello-service"
}

variable "workload_account_ids" {
  description = "Dev, staging and prod account IDs allowed to pull images. Empty in single-account mode."
  type        = list(string)
  default     = []
}

variable "ecr_force_delete" {
  description = "Allow destroying the repository with images in it (demo teardown)."
  type        = bool
  default     = false
}

variable "dns_zone_name" {
  description = "Delegated subdomain zone, e.g. devsecops.example.com. Set via TF_VAR_dns_zone_name; empty disables DNS."
  type        = string
  default     = null
}

variable "repository_id" {
  description = "GitHub repository as owner/name."
  type        = string
}

variable "dev_account_id" {
  description = "Dev account ID. null means this account (single-account mode)."
  type        = string
  default     = null
}

variable "staging_account_id" {
  description = "Staging account ID. null means this account (single-account mode)."
  type        = string
  default     = null
}

variable "prod_account_id" {
  description = "Prod account ID. null means this account (single-account mode)."
  type        = string
  default     = null
}

variable "app_urls" {
  description = "Base URLs per environment for smoke tests when no DNS zone is configured."
  type        = map(string)
  default     = {}
}

variable "approval_emails" {
  description = "Emails asked to approve prod releases. Set via TF_VAR_approval_emails; each must confirm the SNS subscription."
  type        = list(string)
  default     = []
}

variable "enable_inspector" {
  description = "Amazon Inspector enhanced, continuous scanning of ECR images (rescans when new CVEs are published)."
  type        = bool
  default     = true
}

variable "alert_emails" {
  description = "Emails notified when a pipeline fails. Set via TF_VAR_alert_emails."
  type        = list(string)
  default     = []
}

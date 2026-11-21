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

variable "dev_app_url" {
  description = "Dev base URL for smoke tests when no DNS zone is configured."
  type        = string
  default     = ""
}

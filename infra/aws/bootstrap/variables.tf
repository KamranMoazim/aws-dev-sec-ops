variable "project" {
  description = "Short project name used in resource names."
  type        = string
  default     = "devsecops"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,20}$", var.project))
    error_message = "Use 3-20 lowercase letters, digits or hyphens."
  }
}

variable "region" {
  description = "AWS region for the state bucket."
  type        = string
  default     = "us-east-1"
}

variable "budget_limit_usd" {
  description = "Monthly cost budget for this account in USD."
  type        = number
  default     = 50
}

variable "budget_alert_emails" {
  description = "Emails notified at 80% actual and 100% forecasted spend."
  type        = list(string)

  validation {
    condition     = length(var.budget_alert_emails) > 0
    error_message = "Provide at least one email address."
  }
}

variable "noncurrent_state_retention_days" {
  description = "Days to keep old state versions before deletion."
  type        = number
  default     = 90
}

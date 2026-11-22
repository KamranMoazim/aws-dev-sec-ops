variable "project" {
  description = "Short project name used in resource names."
  type        = string
}

variable "alert_emails" {
  description = "Emails notified of high and critical GuardDuty and Security Hub findings."
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "Days to keep CloudTrail and Config logs in S3 (and CloudTrail in CloudWatch Logs)."
  type        = number
  default     = 365
}

variable "force_destroy_logs" {
  description = "Allow destroying the log bucket with objects in it (demo teardown)."
  type        = bool
  default     = false
}

variable "enable_guardduty_runtime_monitoring" {
  description = "GuardDuty Runtime Monitoring with the managed agent for ECS Fargate."
  type        = bool
  default     = true
}

variable "config_recording_frequency" {
  description = "CONTINUOUS or DAILY. DAILY records far fewer configuration items, so it costs less."
  type        = string
  default     = "DAILY"
}

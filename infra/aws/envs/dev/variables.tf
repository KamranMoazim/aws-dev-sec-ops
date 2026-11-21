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
  description = "Role to assume in the dev account. null uses the caller's credentials (single-account mode)."
  type        = string
  default     = null
}

variable "vpc_cidr" {
  description = "VPC CIDR for this environment; keep unique per env to allow peering later."
  type        = string
  default     = "10.10.0.0/16"
}

variable "availability_zones" {
  description = "AZs for this environment's subnets."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "single_nat_gateway" {
  description = "One NAT gateway for all AZs (cheaper, not AZ-resilient)."
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "Retention for VPC flow logs."
  type        = number
  default     = 365
}

variable "secret_recovery_window_days" {
  description = "Days a deleted secret can be restored. 0 for instant demo teardown."
  type        = number
  default     = 7
}

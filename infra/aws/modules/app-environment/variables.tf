variable "project" {
  description = "Short project name used in resource names."
  type        = string
}

variable "environment" {
  description = "Environment name, e.g. dev, staging, prod."
  type        = string
}

variable "app_name" {
  description = "Application, ECR repository and ECS service name."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR; keep unique per env to allow peering later."
  type        = string
}

variable "availability_zones" {
  description = "AZs for this environment's subnets."
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "One NAT gateway for all AZs (cheaper, not AZ-resilient)."
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "Retention for VPC flow logs and WAF logs."
  type        = number
  default     = 365
}

variable "secret_recovery_window_days" {
  description = "Days a deleted secret can be restored. 0 for instant demo teardown."
  type        = number
  default     = 7
}

variable "initial_image_tag" {
  description = "Image tag used only when the release parameter is first created; the pipeline owns it afterwards."
  type        = string
}

variable "ecr_registry_id" {
  description = "Account ID that owns the ECR repository. null means this account (single-account mode)."
  type        = string
  default     = null
}

variable "dns_zone_name" {
  description = "Delegated subdomain zone; the app is served at <hostname>.<zone> over HTTPS. null disables DNS."
  type        = string
  default     = null
}

variable "hostname" {
  description = "Host label under the zone, e.g. dev, staging, app."
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_multi_az" {
  description = "RDS standby in a second AZ."
  type        = bool
  default     = false
}

variable "min_count" {
  description = "Minimum (and initial) task count."
  type        = number
  default     = 1
}

variable "max_count" {
  description = "Autoscaling maximum task count."
  type        = number
  default     = 3
}

variable "deployment_strategy" {
  description = "ROLLING or BLUE_GREEN."
  type        = string
  default     = "ROLLING"
}

variable "bake_time_minutes" {
  description = "Blue/green bake time before the old revision is removed."
  type        = number
  default     = 5
}

variable "enable_waf" {
  description = "Attach a WAF web ACL (AWS managed rules + rate limit) to the load balancer."
  type        = bool
  default     = false
}

variable "waf_rate_limit" {
  description = "Requests per 5 minutes per IP before WAF blocks."
  type        = number
  default     = 2000
}

variable "teardown_friendly" {
  description = "Disable deletion protection and final snapshots so the env can be destroyed quickly."
  type        = bool
  default     = false
}

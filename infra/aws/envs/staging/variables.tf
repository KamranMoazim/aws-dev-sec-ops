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
  description = "Role to assume in the staging account. null uses the caller's credentials (single-account mode)."
  type        = string
  default     = null
}

variable "dns_role_arn" {
  description = "Role in the account owning the DNS zone. null uses the caller (single-account mode)."
  type        = string
  default     = null
}

variable "dns_zone_name" {
  description = "Delegated subdomain zone. Set via TF_VAR_dns_zone_name."
  type        = string
  default     = null
}

variable "app_name" {
  description = "Application, ECR repository and ECS service name."
  type        = string
  default     = "hello-service"
}

variable "ecr_registry_id" {
  description = "Account ID that owns the ECR repository. null means this account (single-account mode)."
  type        = string
  default     = null
}

variable "initial_image_tag" {
  description = "Image tag used only when the release parameter is first created; the pipeline owns it afterwards."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR; unique per env."
  type        = string
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

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "teardown_friendly" {
  description = "Disable deletion protection and final snapshots so the env can be destroyed quickly."
  type        = bool
  default     = false
}

variable "name" {
  description = "Identifier prefix, e.g. devsecops-dev."
  type        = string
}

variable "vpc_id" {
  description = "VPC for the database security group."
  type        = string
}

variable "subnet_ids" {
  description = "Isolated db subnets for the subnet group."
  type        = list(string)
}

variable "allowed_security_groups" {
  description = "Security groups allowed to connect on 5432, as static label => security group ID."
  type        = map(string)
  default     = {}
}

variable "kms_key_arn" {
  description = "KMS key for storage, the managed master secret and Performance Insights."
  type        = string
}

variable "engine_version" {
  description = "PostgreSQL major or major.minor version."
  type        = string
  default     = "17"
}

variable "instance_class" {
  description = "Instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "database_name" {
  description = "Initial database name."
  type        = string
  default     = "hello"
}

variable "master_username" {
  description = "Master user; the password is generated and stored in Secrets Manager by RDS."
  type        = string
  default     = "hello_admin"
}

variable "allocated_storage_gb" {
  description = "Initial storage in GB."
  type        = number
  default     = 20
}

variable "max_allocated_storage_gb" {
  description = "Storage autoscaling ceiling in GB."
  type        = number
  default     = 50
}

variable "multi_az" {
  description = "Standby replica in a second AZ (prod)."
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Automated backup retention."
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Block deletes (enable for prod)."
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot on destroy (demo teardown)."
  type        = bool
  default     = false
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights."
  type        = bool
  default     = false
}

variable "apply_immediately" {
  description = "Apply modifications now instead of in the maintenance window."
  type        = bool
  default     = false
}

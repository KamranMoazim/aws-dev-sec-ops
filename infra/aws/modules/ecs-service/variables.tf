variable "name" {
  description = "Environment prefix and cluster name, e.g. devsecops-dev."
  type        = string
}

variable "service_name" {
  description = "Service and container name, e.g. hello-service."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR, used for task egress to the database."
  type        = string
}

variable "public_subnet_ids" {
  description = "Subnets for the load balancer."
  type        = list(string)
}

variable "app_subnet_ids" {
  description = "Private subnets for tasks."
  type        = list(string)
}

variable "image" {
  description = "Full image URI with tag or digest."
  type        = string
}

variable "container_port" {
  description = "Port the container listens on."
  type        = number
  default     = 3000
}

variable "health_check_path" {
  description = "Load balancer health check path."
  type        = string
  default     = "/health"
}

variable "cpu" {
  description = "Task CPU units."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Task memory in MiB."
  type        = number
  default     = 512
}

variable "cpu_architecture" {
  description = "X86_64 or ARM64; must match the image."
  type        = string
  default     = "X86_64"
}

variable "desired_count" {
  description = "Initial task count; autoscaling owns it afterwards."
  type        = number
  default     = 1
}

variable "min_count" {
  description = "Autoscaling minimum."
  type        = number
  default     = 1
}

variable "max_count" {
  description = "Autoscaling maximum."
  type        = number
  default     = 3
}

variable "cpu_target_percent" {
  description = "Target average CPU for scaling."
  type        = number
  default     = 60
}

variable "environment" {
  description = "Plain environment variables."
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Environment variables injected from Secrets Manager, as name => valueFrom ARN (optionally :json-key::)."
  type        = map(string)
  default     = {}
}

variable "secret_arns" {
  description = "Secret ARNs the execution role may read (without json-key suffixes)."
  type        = list(string)
  default     = []
}

variable "kms_key_arn" {
  description = "KMS key for the log group and secret decryption."
  type        = string
}

variable "log_retention_days" {
  description = "App log retention."
  type        = number
  default     = 365
}

variable "enable_https" {
  description = "Serve HTTPS on 443 and redirect HTTP. Requires certificate_arn."
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ACM certificate for HTTPS; used when enable_https is true."
  type        = string
  default     = null
}

variable "alb_deletion_protection" {
  description = "Protect the load balancer from deletion (enable for prod)."
  type        = bool
  default     = true
}

variable "deployment_strategy" {
  description = "ROLLING or BLUE_GREEN (ECS native blue/green with a second target group)."
  type        = string
  default     = "ROLLING"

  validation {
    condition     = contains(["ROLLING", "BLUE_GREEN"], var.deployment_strategy)
    error_message = "Use ROLLING or BLUE_GREEN."
  }
}

variable "bake_time_minutes" {
  description = "Blue/green: minutes both revisions stay up after the shift. Keep above alarm detection time (about 3 min), or alarms fire too late to roll back."
  type        = number
  default     = 5
}

variable "test_listener_port" {
  description = "Blue/green: ALB port that routes to the new revision before production traffic shifts."
  type        = number
  default     = 8443
}

variable "test_listener_cidrs" {
  description = "Blue/green: CIDRs allowed to reach the test listener; keep private."
  type        = list(string)
  default     = []
}

variable "alarm_actions" {
  description = "SNS topics notified when a service alarm changes state."
  type        = list(string)
  default     = []
}

variable "error_5xx_threshold" {
  description = "Target 5xx responses per minute that trigger the alarm and a deployment rollback."
  type        = number
  default     = 5
}

variable "latency_p99_seconds" {
  description = "p99 target response time (seconds) that triggers the alarm after three minutes."
  type        = number
  default     = 1.5
}

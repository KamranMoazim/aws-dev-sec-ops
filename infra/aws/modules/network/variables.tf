variable "name" {
  description = "Name prefix, e.g. devsecops-dev."
  type        = string
}

variable "cidr_block" {
  description = "VPC CIDR. Split into /20 public, app and db subnets per AZ."
  type        = string
  default     = "10.10.0.0/16"
}

variable "availability_zones" {
  description = "Explicit AZ names, e.g. [\"us-east-1a\", \"us-east-1b\"]. Pinned so subnets never shift."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2 && length(var.availability_zones) <= 4
    error_message = "Provide 2 to 4 availability zones."
  }
}

variable "enable_nat_gateway" {
  description = "Create NAT gateway(s) so app subnets can reach the internet."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "One shared NAT gateway (cheap) instead of one per AZ (highly available)."
  type        = bool
  default     = true
}

variable "enable_s3_endpoint" {
  description = "Free S3 gateway endpoint; keeps ECR layer pulls off the NAT gateway."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "KMS key used to encrypt the flow log group."
  type        = string
}

variable "flow_log_retention_days" {
  description = "Retention for VPC flow logs."
  type        = number
  default     = 365
}

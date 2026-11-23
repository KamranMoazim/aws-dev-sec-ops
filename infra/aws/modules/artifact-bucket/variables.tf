variable "name" {
  description = "Bucket name (globally unique, at most 63 characters)."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key for default bucket encryption."
  type        = string
}

variable "retention_days" {
  description = "Days to keep artifacts."
  type        = number
  default     = 30
}

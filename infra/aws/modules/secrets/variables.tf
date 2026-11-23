variable "name" {
  description = "Name prefix, e.g. devsecops-dev. Used for the KMS alias and secret paths."
  type        = string
}

variable "secrets" {
  description = "Secret containers to create, as name => description. Values are set outside Terraform."
  type        = map(string)
  default     = {}
}

variable "key_deletion_window_days" {
  description = "Waiting period before the KMS key is deleted."
  type        = number
  default     = 30
}

variable "secret_recovery_window_days" {
  description = "Days a deleted secret can be restored. 0 deletes immediately (demo teardown)."
  type        = number
  default     = 7
}

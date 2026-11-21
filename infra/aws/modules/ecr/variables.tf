variable "name" {
  description = "Repository name, e.g. hello-service."
  type        = string
}

variable "pull_account_ids" {
  description = "Workload account IDs allowed to pull images. Empty in single-account mode."
  type        = list(string)
  default     = []
}

variable "untagged_expiry_days" {
  description = "Days before untagged images are expired."
  type        = number
  default     = 7
}

variable "max_image_count" {
  description = "Number of most recent images to keep (rollback window)."
  type        = number
  default     = 30
}

variable "force_delete" {
  description = "Allow deleting the repository while it still has images (demo teardown)."
  type        = bool
  default     = false
}

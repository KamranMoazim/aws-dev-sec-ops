variable "name" {
  description = "Pipeline name, e.g. devsecops-infra."
  type        = string
}

variable "project" {
  description = "Project prefix; the apply role may only manage IAM roles named <project>-*."
  type        = string
}

variable "connection_arn" {
  description = "CodeConnections connection to the Git provider (must be AVAILABLE)."
  type        = string
}

variable "repository_id" {
  description = "Repository as owner/name."
  type        = string
}

variable "branch" {
  description = "Branch whose infrastructure changes are planned and applied."
  type        = string
  default     = "develop"
}

variable "trigger_file_paths" {
  description = "Changes under these paths start the pipeline."
  type        = list(string)
  default     = ["infra/**", "buildspecs/buildspec-infra-*", "scripts/ci/terraform-*", "scripts/security/**"]
}

variable "environments" {
  description = "Environment roots under infra/aws/envs to plan and apply, e.g. [\"dev\"]. Never the root that holds this pipeline."
  type        = list(string)

  validation {
    condition     = length(var.environments) > 0
    error_message = "Provide at least one environment."
  }
}

variable "state_bucket" {
  description = "Terraform state bucket."
  type        = string
}

variable "protected_state_prefixes" {
  description = "State keys the pipeline may never read or write (the bootstrap and the root holding this pipeline)."
  type        = list(string)
  default     = ["bootstrap/", "envs/shared/"]
}

variable "state_kms_key_arn" {
  description = "KMS key encrypting Terraform state."
  type        = string
}

variable "terraform_variables" {
  description = "TF_VAR_* values the plan needs that are not committed (e.g. the DNS zone), as name => value."
  type        = map(string)
  default     = {}
}

variable "approval_topic_arn" {
  description = "SNS topic notified when a plan waits for approval."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key for artifacts and build logs."
  type        = string
}

variable "build_image" {
  description = "CodeBuild image."
  type        = string
  default     = "aws/codebuild/amazonlinux-x86_64-standard:5.0"
}

variable "build_compute_type" {
  description = "CodeBuild compute type."
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
}

variable "log_retention_days" {
  description = "CodeBuild log retention."
  type        = number
  default     = 365
}

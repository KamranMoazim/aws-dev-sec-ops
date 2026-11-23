variable "name" {
  description = "Pipeline name, e.g. devsecops-hello-service."
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
  description = "Branch the source action checks out on a manual start."
  type        = string
  default     = "develop"
}

variable "trigger_branches" {
  description = "Branch globs whose pushes start the pipeline, e.g. [\"release/*\"]. Empty uses branch."
  type        = list(string)
  default     = []
}

variable "trigger_file_paths" {
  description = "Only changes under these paths start the pipeline. null triggers on every push."
  type        = list(string)
  default     = ["app/**", "buildspecs/**", "scripts/**"]
}

variable "trigger_file_path_excludes" {
  description = "Changes only under these paths do not start the pipeline."
  type        = list(string)
  default     = []
}

variable "ecr_repository_url" {
  description = "Image repository URL."
  type        = string
}

variable "ecr_repository_arn" {
  description = "Image repository ARN."
  type        = string
}

variable "container_name" {
  description = "Container name in the task definition."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key for artifacts and build logs."
  type        = string
}

variable "environments" {
  description = "Deployment targets in promotion order. approval adds a manual gate before the env; dast runs a ZAP baseline after the smoke test."
  type = list(object({
    name                     = string
    cluster_name             = string
    service_name             = string
    service_arn              = string
    task_role_arns           = list(string)
    app_url                  = string
    image_tag_parameter_name = string
    image_tag_parameter_arn  = string
    approval                 = optional(bool, false)
    dast                     = optional(bool, false)
  }))

  validation {
    condition     = length(var.environments) > 0
    error_message = "Provide at least one environment."
  }
}

variable "approval_topic_arn" {
  description = "SNS topic notified for manual approvals. Required when any environment has approval."
  type        = string
  default     = null
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

variable "artifact_retention_days" {
  description = "Days to keep pipeline artifacts."
  type        = number
  default     = 30
}

variable "artifact_bucket_name" {
  description = "Artifact bucket name override when <name>-artifacts-<account>-<region> exceeds 63 characters."
  type        = string
  default     = null
}

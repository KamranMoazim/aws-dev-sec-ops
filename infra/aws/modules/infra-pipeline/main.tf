terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.region
}

module "artifacts" {
  source = "../artifact-bucket"

  name        = "${var.name}-artifacts-${local.account_id}-${local.region}"
  kms_key_arn = var.kms_key_arn
}

# QUEUED keeps applies in order; a superseded run could otherwise drop an approved change.
resource "aws_codepipeline" "this" {
  name           = var.name
  pipeline_type  = "V2"
  execution_mode = "QUEUED"
  role_arn       = aws_iam_role.pipeline.arn

  artifact_store {
    type     = "S3"
    location = module.artifacts.bucket

    encryption_key {
      type = "KMS"
      id   = var.kms_key_arn
    }
  }

  trigger {
    provider_type = "CodeStarSourceConnection"

    git_configuration {
      source_action_name = "Source"

      push {
        branches {
          includes = [var.branch]
        }

        file_paths {
          includes = var.trigger_file_paths
        }
      }
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source"]

      configuration = {
        ConnectionArn        = var.connection_arn
        FullRepositoryId     = var.repository_id
        BranchName           = var.branch
        OutputArtifactFormat = "CODE_ZIP"
        DetectChanges        = "false"
      }
    }
  }

  stage {
    name = "Validate"

    action {
      name            = "FmtValidateCheckov"
      category        = "Test"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source"]

      configuration = {
        ProjectName = aws_codebuild_project.this["validate"].name
      }
    }
  }

  stage {
    name = "Plan"

    dynamic "action" {
      for_each = var.environments

      content {
        name             = "Plan-${action.value}"
        category         = "Build"
        owner            = "AWS"
        provider         = "CodeBuild"
        version          = "1"
        namespace        = "Plan_${action.value}"
        input_artifacts  = ["source"]
        output_artifacts = ["plan_${action.value}"]

        configuration = {
          ProjectName = aws_codebuild_project.this["plan"].name
          EnvironmentVariables = jsonencode([
            { name = "ENVIRONMENT", value = action.value, type = "PLAINTEXT" }
          ])
        }
      }
    }
  }

  stage {
    name = "Approve"

    action {
      name     = "ReviewPlan"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

      configuration = {
        NotificationArn = var.approval_topic_arn
        CustomData      = "Terraform plan: ${join(" | ", [for env in var.environments : "#{Plan_${env}.PLAN_SUMMARY}"])}. Full plan in the Plan build log."
      }
    }
  }

  stage {
    name = "Apply"

    dynamic "action" {
      for_each = var.environments

      content {
        name            = "Apply-${action.value}"
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        version         = "1"
        input_artifacts = ["source", "plan_${action.value}"]

        configuration = {
          ProjectName   = aws_codebuild_project.this["apply"].name
          PrimarySource = "source"
          EnvironmentVariables = jsonencode([
            { name = "ENVIRONMENT", value = action.value, type = "PLAINTEXT" }
          ])
        }
      }
    }
  }
}

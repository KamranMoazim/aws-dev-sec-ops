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

resource "aws_codepipeline" "this" {
  name          = var.name
  pipeline_type = "V2"
  role_arn      = aws_iam_role.pipeline.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.artifacts.bucket

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
      namespace        = "SourceVariables"
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
    name = "Build"

    action {
      name             = "BuildTestPush"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      namespace        = "Build"
      input_artifacts  = ["source"]
      output_artifacts = ["image"]

      configuration = {
        ProjectName = aws_codebuild_project.build.name
        EnvironmentVariables = jsonencode([
          { name = "COMMIT_ID", value = "#{SourceVariables.CommitId}", type = "PLAINTEXT" }
        ])
      }
    }
  }

  stage {
    name = "DeployDev"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["image"]
      run_order       = 1

      configuration = {
        ClusterName       = var.dev.cluster_name
        ServiceName       = var.dev.service_name
        FileName          = "imagedefinitions.json"
        DeploymentTimeout = "15"
      }
    }

    action {
      name            = "SmokeTest"
      category        = "Test"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source"]
      run_order       = 2

      configuration = {
        ProjectName = aws_codebuild_project.smoke.name
        EnvironmentVariables = jsonencode([
          { name = "IMAGE_TAG", value = "#{Build.IMAGE_TAG}", type = "PLAINTEXT" },
          { name = "APP_URL", value = var.dev.app_url, type = "PLAINTEXT" },
          { name = "IMAGE_TAG_PARAMETER", value = var.dev.image_tag_parameter_name, type = "PLAINTEXT" },
        ])
      }
    }
  }
}

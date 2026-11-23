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
  any_dast   = anytrue([for env in var.environments : env.dast])

  deploy_stages = flatten([for env in var.environments : concat(
    env.approval ? [{
      name = "Approve${title(env.name)}"
      actions = [{
        name            = "Approve"
        category        = "Approval"
        provider        = "Manual"
        input_artifacts = []
        run_order       = 1
        timeout_minutes = 1440
        configuration = tomap({
          NotificationArn = var.approval_topic_arn
          CustomData      = "Image #{Build.IMAGE_TAG} passed all earlier stages. Approve to deploy it to ${env.name}."
        })
      }]
    }] : [],
    [{
      name = "Deploy${title(env.name)}"
      actions = concat(
        [
          {
            name            = "Deploy"
            category        = "Deploy"
            provider        = "ECS"
            input_artifacts = ["image"]
            run_order       = 1
            timeout_minutes = null
            configuration = tomap({
              ClusterName       = env.cluster_name
              ServiceName       = env.service_name
              FileName          = "imagedefinitions.json"
              DeploymentTimeout = "30"
            })
          },
          {
            name            = "SmokeTest"
            category        = "Test"
            provider        = "CodeBuild"
            input_artifacts = ["source"]
            run_order       = 2
            timeout_minutes = null
            configuration = tomap({
              ProjectName = aws_codebuild_project.smoke.name
              EnvironmentVariables = jsonencode([
                { name = "IMAGE_TAG", value = "#{Build.IMAGE_TAG}", type = "PLAINTEXT" },
                { name = "ECS_CLUSTER", value = env.cluster_name, type = "PLAINTEXT" },
                { name = "ECS_SERVICE", value = env.service_name, type = "PLAINTEXT" },
                { name = "APP_URL", value = env.app_url, type = "PLAINTEXT" },
                { name = "IMAGE_TAG_PARAMETER", value = env.image_tag_parameter_name, type = "PLAINTEXT" },
              ])
            })
          },
        ],
        env.dast ? [{
          name            = "DastBaseline"
          category        = "Test"
          provider        = "CodeBuild"
          input_artifacts = ["source"]
          run_order       = 3
          timeout_minutes = null
          configuration = tomap({
            ProjectName = aws_codebuild_project.dast[0].name
            EnvironmentVariables = jsonencode([
              { name = "APP_URL", value = env.app_url, type = "PLAINTEXT" },
            ])
          })
        }] : [],
      )
    }],
  )])
}

resource "aws_codepipeline" "this" {
  name          = var.name
  pipeline_type = "V2"
  role_arn      = aws_iam_role.pipeline.arn

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
          includes = length(var.trigger_branches) > 0 ? var.trigger_branches : [var.branch]
        }

        dynamic "file_paths" {
          for_each = var.trigger_file_paths == null ? [] : [var.trigger_file_paths]

          content {
            includes = file_paths.value
            excludes = length(var.trigger_file_path_excludes) > 0 ? var.trigger_file_path_excludes : null
          }
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
    name = "Scan"

    action {
      name            = "SourceScans"
      category        = "Test"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source"]

      configuration = {
        ProjectName = aws_codebuild_project.security.name
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

  dynamic "stage" {
    for_each = local.deploy_stages

    content {
      name = stage.value.name

      dynamic "action" {
        for_each = stage.value.actions

        content {
          name               = action.value.name
          category           = action.value.category
          owner              = "AWS"
          provider           = action.value.provider
          version            = "1"
          input_artifacts    = action.value.input_artifacts
          run_order          = action.value.run_order
          timeout_in_minutes = action.value.timeout_minutes
          configuration      = action.value.configuration
        }
      }
    }
  }
}

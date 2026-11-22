resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/codebuild/${var.name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
}

locals {
  projects = {
    validate = { description = "terraform fmt, validate and Checkov", role = aws_iam_role.validate.arn }
    plan     = { description = "terraform plan with read-only credentials", role = aws_iam_role.plan.arn }
    apply    = { description = "terraform apply of the approved plan", role = aws_iam_role.apply.arn }
  }
}

resource "aws_codebuild_project" "this" {
  for_each = local.projects

  name           = "${var.name}-${each.key}"
  description    = each.value.description
  service_role   = each.value.role
  encryption_key = var.kms_key_arn
  build_timeout  = 60

  artifacts {
    type = "CODEPIPELINE"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspecs/buildspec-infra-${each.key}.yml"
  }

  environment {
    compute_type = var.build_compute_type
    image        = var.build_image
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "STATE_BUCKET"
      value = var.state_bucket
    }

    environment_variable {
      name  = "STATE_KMS_KEY_ARN"
      value = var.state_kms_key_arn
    }

    dynamic "environment_variable" {
      for_each = each.key == "plan" ? var.terraform_variables : {}

      content {
        name  = "TF_VAR_${environment_variable.key}"
        value = environment_variable.value
      }
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.codebuild.name
      stream_name = each.key
    }
  }
}

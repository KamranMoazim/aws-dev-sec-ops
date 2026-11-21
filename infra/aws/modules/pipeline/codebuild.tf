resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/codebuild/${var.name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
}

resource "aws_codebuild_project" "build" {
  #checkov:skip=CKV_AWS_316:Privileged mode is required to run docker build
  name           = "${var.name}-build"
  description    = "Lint, unit test, build and push the container image"
  service_role   = aws_iam_role.build.arn
  encryption_key = var.kms_key_arn
  build_timeout  = 30

  artifacts {
    type = "CODEPIPELINE"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspecs/buildspec-build.yml"
  }

  environment {
    compute_type    = var.build_compute_type
    image           = var.build_image
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "ECR_REPOSITORY_URL"
      value = var.ecr_repository_url
    }

    environment_variable {
      name  = "CONTAINER_NAME"
      value = var.container_name
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.codebuild.name
      stream_name = "build"
    }
  }
}

resource "aws_codebuild_project" "security" {
  name           = "${var.name}-security"
  description    = "Secrets, SAST, SCA and IaC scans; fails on HIGH/CRITICAL findings"
  service_role   = aws_iam_role.security.arn
  encryption_key = var.kms_key_arn
  build_timeout  = 30

  artifacts {
    type = "CODEPIPELINE"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspecs/buildspec-security.yml"
  }

  environment {
    compute_type = var.build_compute_type
    image        = var.build_image
    type         = "LINUX_CONTAINER"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.codebuild.name
      stream_name = "security"
    }
  }
}

resource "aws_codebuild_project" "smoke" {
  name           = "${var.name}-smoke"
  description    = "Smoke test a deployed environment and record the released image tag"
  service_role   = aws_iam_role.smoke.arn
  encryption_key = var.kms_key_arn
  build_timeout  = 15

  artifacts {
    type = "CODEPIPELINE"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspecs/buildspec-smoke.yml"
  }

  environment {
    compute_type = var.build_compute_type
    image        = var.build_image
    type         = "LINUX_CONTAINER"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.codebuild.name
      stream_name = "smoke"
    }
  }
}

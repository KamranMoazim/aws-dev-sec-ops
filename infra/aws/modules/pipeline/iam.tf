locals {
  codebuild_project_arns = concat(
    [
      aws_codebuild_project.build.arn,
      aws_codebuild_project.security.arn,
      aws_codebuild_project.smoke.arn,
    ],
    aws_codebuild_project.dast[*].arn,
  )
  service_arns         = [for env in var.environments : env.service_arn]
  task_role_arns       = flatten([for env in var.environments : env.task_role_arns])
  image_tag_parameters = [for env in var.environments : env.image_tag_parameter_arn]
  needs_approval       = anytrue([for env in var.environments : env.approval])
}

data "aws_iam_policy_document" "artifacts_access" {
  statement {
    sid       = "ArtifactObjects"
    actions   = ["s3:GetObject", "s3:GetObjectVersion", "s3:PutObject"]
    resources = ["${module.artifacts.arn}/*"]
  }

  statement {
    sid       = "ArtifactBucket"
    actions   = ["s3:GetBucketLocation", "s3:GetBucketVersioning", "s3:ListBucket"]
    resources = [module.artifacts.arn]
  }

  statement {
    sid       = "ArtifactEncryption"
    actions   = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey*", "kms:DescribeKey"]
    resources = [var.kms_key_arn]
  }
}

data "aws_iam_policy_document" "codebuild_logs" {
  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.codebuild.arn}:*"]
  }
}

data "aws_iam_policy_document" "codebuild_reports" {
  statement {
    actions = [
      "codebuild:BatchPutTestCases",
      "codebuild:CreateReport",
      "codebuild:CreateReportGroup",
      "codebuild:UpdateReport",
    ]
    resources = ["arn:aws:codebuild:${local.region}:${local.account_id}:report-group/${var.name}-*"]
  }
}

data "aws_iam_policy_document" "pipeline_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "pipeline" {
  #checkov:skip=CKV_AWS_356:RegisterTaskDefinition and DescribeTaskDefinition do not support resource-level permissions
  source_policy_documents = [data.aws_iam_policy_document.artifacts_access.json]

  statement {
    sid       = "UseConnection"
    actions   = ["codeconnections:UseConnection", "codestar-connections:UseConnection"]
    resources = [var.connection_arn]
  }

  statement {
    sid       = "RunBuilds"
    actions   = ["codebuild:StartBuild", "codebuild:BatchGetBuilds"]
    resources = local.codebuild_project_arns
  }

  statement {
    sid       = "DeployService"
    actions   = ["ecs:DescribeServices", "ecs:UpdateService"]
    resources = local.service_arns
  }

  statement {
    sid = "RegisterTaskDefinitions"
    actions = [
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition",
      "ecs:TagResource",
      "ecs:ListTasks",
      "ecs:DescribeTasks",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "PassTaskRoles"
    actions   = ["iam:PassRole"]
    resources = local.task_role_arns

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }

  dynamic "statement" {
    for_each = local.needs_approval ? [var.approval_topic_arn] : []

    content {
      sid       = "NotifyApprovers"
      actions   = ["sns:Publish"]
      resources = [statement.value]
    }
  }
}

resource "aws_iam_role" "pipeline" {
  name               = "${var.name}-pipeline"
  assume_role_policy = data.aws_iam_policy_document.pipeline_assume.json
}

resource "aws_iam_role_policy" "pipeline" {
  name   = "pipeline"
  role   = aws_iam_role.pipeline.id
  policy = data.aws_iam_policy_document.pipeline.json
}

data "aws_iam_policy_document" "codebuild_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }
}

data "aws_iam_policy_document" "build" {
  source_policy_documents = [
    data.aws_iam_policy_document.artifacts_access.json,
    data.aws_iam_policy_document.codebuild_logs.json,
    data.aws_iam_policy_document.codebuild_reports.json,
  ]

  statement {
    sid       = "EcrLogin"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "EcrPush"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = [var.ecr_repository_arn]
  }
}

resource "aws_iam_role" "build" {
  name               = "${var.name}-build"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
}

resource "aws_iam_role_policy" "build" {
  name   = "build"
  role   = aws_iam_role.build.id
  policy = data.aws_iam_policy_document.build.json
}

resource "aws_iam_role" "security" {
  name               = "${var.name}-security"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
}

resource "aws_iam_role_policy" "security" {
  name   = "security"
  role   = aws_iam_role.security.id
  policy = data.aws_iam_policy_document.security.json
}

data "aws_iam_policy_document" "security" {
  source_policy_documents = [
    data.aws_iam_policy_document.artifacts_access.json,
    data.aws_iam_policy_document.codebuild_logs.json,
    data.aws_iam_policy_document.codebuild_reports.json,
  ]
}

data "aws_iam_policy_document" "smoke" {
  source_policy_documents = [
    data.aws_iam_policy_document.artifacts_access.json,
    data.aws_iam_policy_document.codebuild_logs.json,
  ]

  statement {
    sid       = "VerifyDeployment"
    actions   = ["ecs:DescribeServices"]
    resources = local.service_arns
  }

  statement {
    sid       = "ReadTaskDefinition"
    actions   = ["ecs:DescribeTaskDefinition"]
    resources = ["*"]
  }

  statement {
    sid       = "RecordReleasedTag"
    actions   = ["ssm:PutParameter"]
    resources = local.image_tag_parameters
  }
}

resource "aws_iam_role" "smoke" {
  name               = "${var.name}-smoke"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
}

resource "aws_iam_role_policy" "smoke" {
  name   = "smoke"
  role   = aws_iam_role.smoke.id
  policy = data.aws_iam_policy_document.smoke.json
}

resource "aws_iam_role" "dast" {
  count = local.any_dast ? 1 : 0

  name               = "${var.name}-dast"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
}

resource "aws_iam_role_policy" "dast" {
  count = local.any_dast ? 1 : 0

  name   = "dast"
  role   = aws_iam_role.dast[0].id
  policy = data.aws_iam_policy_document.security.json
}

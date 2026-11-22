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

data "aws_iam_policy_document" "codebuild_base" {
  source_policy_documents = [data.aws_iam_policy_document.artifacts_access.json]

  statement {
    sid       = "BuildLogs"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.codebuild.arn}:*"]
  }

  statement {
    sid = "BuildReports"
    actions = [
      "codebuild:BatchPutTestCases",
      "codebuild:CreateReport",
      "codebuild:CreateReportGroup",
      "codebuild:UpdateReport",
    ]
    resources = ["arn:aws:codebuild:${local.region}:${local.account_id}:report-group/${var.name}-*"]
  }
}

# Plan reads state and holds the lock; only apply writes state. Neither reaches bootstrap or shared state.
data "aws_iam_policy_document" "state_lock" {
  statement {
    sid       = "ListStateBucket"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.state_bucket}"]
  }

  statement {
    sid       = "ReadEnvironmentState"
    actions   = ["s3:GetObject"]
    resources = [for env in var.environments : "arn:aws:s3:::${var.state_bucket}/envs/${env}/*"]
  }

  statement {
    sid       = "HoldStateLock"
    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = [for env in var.environments : "arn:aws:s3:::${var.state_bucket}/envs/${env}/terraform.tfstate.tflock"]
  }

  statement {
    sid       = "DenyProtectedState"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [for prefix in var.protected_state_prefixes : "arn:aws:s3:::${var.state_bucket}/${prefix}*"]
  }

  statement {
    sid       = "StateEncryption"
    actions   = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey*", "kms:DescribeKey"]
    resources = [var.state_kms_key_arn]
  }
}

data "aws_iam_policy_document" "state_write" {
  source_policy_documents = [data.aws_iam_policy_document.state_lock.json]

  statement {
    sid       = "WriteEnvironmentState"
    actions   = ["s3:PutObject"]
    resources = [for env in var.environments : "arn:aws:s3:::${var.state_bucket}/envs/${env}/terraform.tfstate"]
  }
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

resource "aws_iam_role" "validate" {
  name               = "${var.name}-validate"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
}

resource "aws_iam_role_policy" "validate" {
  name   = "validate"
  role   = aws_iam_role.validate.id
  policy = data.aws_iam_policy_document.codebuild_base.json
}

resource "aws_iam_role" "plan" {
  name               = "${var.name}-plan"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
}

data "aws_iam_policy_document" "plan" {
  source_policy_documents = [
    data.aws_iam_policy_document.codebuild_base.json,
    data.aws_iam_policy_document.state_lock.json,
  ]
}

resource "aws_iam_role_policy" "plan" {
  name   = "plan"
  role   = aws_iam_role.plan.id
  policy = data.aws_iam_policy_document.plan.json
}

resource "aws_iam_role_policy_attachment" "plan_read_only" {
  role       = aws_iam_role.plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role" "apply" {
  name               = "${var.name}-apply"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
}

# PowerUserAccess excludes IAM; project roles are managed here by name prefix only.
data "aws_iam_policy_document" "apply" {
  source_policy_documents = [
    data.aws_iam_policy_document.codebuild_base.json,
    data.aws_iam_policy_document.state_write.json,
  ]

  statement {
    sid = "ManageProjectRoles"
    actions = [
      "iam:AttachRolePolicy",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:DeleteRolePolicy",
      "iam:DetachRolePolicy",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:ListRolePolicies",
      "iam:PassRole",
      "iam:PutRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:UpdateRole",
    ]
    resources = ["arn:aws:iam::${local.account_id}:role/${var.project}-*"]
  }

  statement {
    sid       = "ServiceLinkedRoles"
    actions   = ["iam:CreateServiceLinkedRole"]
    resources = ["arn:aws:iam::${local.account_id}:role/aws-service-role/*"]
  }

  statement {
    sid       = "ReadManagedPolicies"
    actions   = ["iam:GetPolicy", "iam:GetPolicyVersion"]
    resources = ["arn:aws:iam::aws:policy/*"]
  }
}

resource "aws_iam_role_policy" "apply" {
  name   = "apply"
  role   = aws_iam_role.apply.id
  policy = data.aws_iam_policy_document.apply.json
}

resource "aws_iam_role_policy_attachment" "apply_power_user" {
  role       = aws_iam_role.apply.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
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
  source_policy_documents = [data.aws_iam_policy_document.artifacts_access.json]

  statement {
    sid       = "UseConnection"
    actions   = ["codeconnections:UseConnection", "codestar-connections:UseConnection"]
    resources = [var.connection_arn]
  }

  statement {
    sid       = "RunBuilds"
    actions   = ["codebuild:StartBuild", "codebuild:BatchGetBuilds"]
    resources = [for project in aws_codebuild_project.this : project.arn]
  }

  statement {
    sid       = "NotifyApprovers"
    actions   = ["sns:Publish"]
    resources = [var.approval_topic_arn]
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

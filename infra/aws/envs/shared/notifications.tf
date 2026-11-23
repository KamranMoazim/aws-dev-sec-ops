resource "aws_sns_topic" "pipeline_alerts" {
  name              = "${var.project}-pipeline-alerts"
  kms_master_key_id = module.shared_kms.kms_key_arn
}

data "aws_iam_policy_document" "pipeline_alerts" {
  statement {
    sid       = "CodeStarNotifications"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.pipeline_alerts.arn]

    principals {
      type        = "Service"
      identifiers = ["codestar-notifications.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sns_topic_policy" "pipeline_alerts" {
  arn    = aws_sns_topic.pipeline_alerts.arn
  policy = data.aws_iam_policy_document.pipeline_alerts.json
}

resource "aws_sns_topic_subscription" "pipeline_alerts" {
  for_each = toset(var.alert_emails)

  topic_arn = aws_sns_topic.pipeline_alerts.arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_codestarnotifications_notification_rule" "pipeline_failed" {
  for_each = {
    app     = module.app_pipeline.pipeline_arn
    release = module.release_pipeline.pipeline_arn
    infra   = module.infra_pipeline.pipeline_arn
  }

  name           = "${var.project}-${each.key}-pipeline-failed"
  resource       = each.value
  detail_type    = "BASIC"
  event_type_ids = ["codepipeline-pipeline-pipeline-execution-failed"]

  target {
    address = aws_sns_topic.pipeline_alerts.arn
  }

  depends_on = [aws_sns_topic_policy.pipeline_alerts]
}

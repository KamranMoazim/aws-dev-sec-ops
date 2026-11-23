resource "aws_sns_topic" "alerts" {
  name              = "${local.name}-alerts"
  kms_master_key_id = aws_kms_key.this.arn
}

data "aws_iam_policy_document" "alerts" {
  statement {
    sid       = "EventBridgeFindings"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.alerts.arn]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }
}

resource "aws_sns_topic_policy" "alerts" {
  arn    = aws_sns_topic.alerts.arn
  policy = data.aws_iam_policy_document.alerts.json
}

resource "aws_sns_topic_subscription" "alerts" {
  for_each = toset(var.alert_emails)

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = each.value
}

locals {
  finding_rules = {
    guardduty-high = {
      description = "GuardDuty findings with severity 7 or higher"
      pattern = {
        source        = ["aws.guardduty"]
        "detail-type" = ["GuardDuty Finding"]
        detail        = { severity = [{ numeric = [">=", 7] }] }
      }
    }
    securityhub-critical = {
      description = "New active HIGH or CRITICAL Security Hub findings"
      pattern = {
        source        = ["aws.securityhub"]
        "detail-type" = ["Security Hub Findings - Imported"]
        detail = {
          findings = {
            Severity    = { Label = ["HIGH", "CRITICAL"] }
            Workflow    = { Status = ["NEW"] }
            RecordState = ["ACTIVE"]
          }
        }
      }
    }
  }
}

resource "aws_cloudwatch_event_rule" "findings" {
  for_each = local.finding_rules

  name          = "${local.name}-${each.key}"
  description   = each.value.description
  event_pattern = jsonencode(each.value.pattern)
}

resource "aws_cloudwatch_event_target" "findings" {
  for_each = local.finding_rules

  rule      = aws_cloudwatch_event_rule.findings[each.key].name
  target_id = "sns"
  arn       = aws_sns_topic.alerts.arn
}

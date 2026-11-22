resource "aws_guardduty_detector" "this" {
  #checkov:skip=CKV2_AWS_3:Single account today; org-wide auto-enable needs member accounts and a delegated admin
  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

resource "aws_guardduty_detector_feature" "s3_data_events" {
  detector_id = aws_guardduty_detector.this.id
  name        = "S3_DATA_EVENTS"
  status      = "ENABLED"
}

# The managed agent is added to new Fargate tasks; running tasks pick it up on their next deployment.
resource "aws_guardduty_detector_feature" "runtime_monitoring" {
  detector_id = aws_guardduty_detector.this.id
  name        = "RUNTIME_MONITORING"
  status      = var.enable_guardduty_runtime_monitoring ? "ENABLED" : "DISABLED"

  additional_configuration {
    name   = "ECS_FARGATE_AGENT_MANAGEMENT"
    status = var.enable_guardduty_runtime_monitoring ? "ENABLED" : "DISABLED"
  }

  # GuardDuty adds these with the feature; declaring them keeps plans free of drift.
  additional_configuration {
    name   = "EC2_AGENT_MANAGEMENT"
    status = "DISABLED"
  }

  additional_configuration {
    name   = "EKS_ADDON_MANAGEMENT"
    status = "DISABLED"
  }
}

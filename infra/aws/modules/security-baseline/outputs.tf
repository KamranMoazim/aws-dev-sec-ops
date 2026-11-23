output "log_bucket" {
  description = "S3 bucket holding CloudTrail and Config logs."
  value       = aws_s3_bucket.logs.id
}

output "trail_arn" {
  description = "Multi-region CloudTrail trail."
  value       = aws_cloudtrail.this.arn
}

output "guardduty_detector_id" {
  description = "GuardDuty detector."
  value       = aws_guardduty_detector.this.id
}

output "alerts_topic_arn" {
  description = "SNS topic for high and critical findings."
  value       = aws_sns_topic.alerts.arn
}

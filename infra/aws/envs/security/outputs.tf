output "log_bucket" {
  description = "Audit log bucket (CloudTrail and Config)."
  value       = module.baseline.log_bucket
}

output "trail_arn" {
  description = "Multi-region CloudTrail trail."
  value       = module.baseline.trail_arn
}

output "guardduty_detector_id" {
  description = "GuardDuty detector."
  value       = module.baseline.guardduty_detector_id
}

output "alerts_topic_arn" {
  description = "SNS topic for high and critical findings."
  value       = module.baseline.alerts_topic_arn
}

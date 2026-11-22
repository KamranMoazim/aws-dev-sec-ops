output "pipeline_name" {
  description = "Infrastructure pipeline name."
  value       = aws_codepipeline.this.name
}

output "pipeline_arn" {
  description = "Infrastructure pipeline ARN."
  value       = aws_codepipeline.this.arn
}

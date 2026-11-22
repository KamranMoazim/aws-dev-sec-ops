output "pipeline_name" {
  description = "CodePipeline name."
  value       = aws_codepipeline.this.name
}

output "artifact_bucket" {
  description = "Artifact bucket name."
  value       = aws_s3_bucket.artifacts.bucket
}

output "build_project_name" {
  description = "Build CodeBuild project."
  value       = aws_codebuild_project.build.name
}

output "pipeline_arn" {
  description = "CodePipeline ARN."
  value       = aws_codepipeline.this.arn
}

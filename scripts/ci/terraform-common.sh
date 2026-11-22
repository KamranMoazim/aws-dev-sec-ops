#!/usr/bin/env bash
# Sourced by the terraform-* scripts: pinned Terraform on PATH and backend init from environment variables
# (STATE_BUCKET, STATE_KMS_KEY_ARN, AWS_REGION) so no account-specific backend file is committed.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export PATH="${TOOLS_DIR:-$REPO_ROOT/.tools}/bin:$PATH"
export TF_IN_AUTOMATION=1
export TF_INPUT=0

terraform_init_backend() {
  local root="$1"
  terraform -chdir="$root" init -no-color \
    -backend-config="bucket=$STATE_BUCKET" \
    -backend-config="region=$AWS_REGION" \
    -backend-config="encrypt=true" \
    -backend-config="kms_key_id=$STATE_KMS_KEY_ARN" \
    -backend-config="use_lockfile=true"
}

# Prints the released image tag of an app environment (empty for roots without an ECS service).
# Fails while an app deployment is in flight: a plan or apply then would point the service at the old image.
released_tag_when_idle() {
  local root="$1" cluster service parameter released_tag deployments running_task_definition running_image
  cluster="$(terraform -chdir="$root" output -raw ecs_cluster_name 2>/dev/null)" || return 0
  service="$(terraform -chdir="$root" output -raw ecs_service_name)"
  parameter="$(terraform -chdir="$root" output -raw image_tag_parameter)"
  released_tag="$(aws ssm get-parameter --name "$parameter" --query Parameter.Value --output text)"
  read -r deployments running_task_definition < <(aws ecs describe-services --cluster "$cluster" --services "$service" \
    --query 'services[0].[length(deployments[?rolloutState!=`COMPLETED`]), taskDefinition]' --output text)
  running_image="$(aws ecs describe-task-definition --task-definition "$running_task_definition" \
    --query 'taskDefinition.containerDefinitions[0].image' --output text)"
  if [ "$deployments" != "0" ] || [ "${running_image##*:}" != "$released_tag" ]; then
    echo "App deployment in flight: $service runs ${running_image##*:}, released tag is $released_tag." >&2
    echo "Re-run the infrastructure pipeline after the app pipeline finishes." >&2
    return 1
  fi
  echo "$released_tag"
}

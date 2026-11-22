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

# A plan taken between an app deploy and its smoke test would point the service back at the old image.
assert_no_app_deploy_in_flight() {
  local root="$1" cluster service parameter released_tag running_task_definition running_image
  cluster="$(terraform -chdir="$root" output -raw ecs_cluster_name 2>/dev/null)" || return 0
  service="$(terraform -chdir="$root" output -raw ecs_service_name)"
  parameter="$(terraform -chdir="$root" output -raw image_tag_parameter)"
  released_tag="$(aws ssm get-parameter --name "$parameter" --query Parameter.Value --output text)"
  running_task_definition="$(aws ecs describe-services --cluster "$cluster" --services "$service" \
    --query 'services[0].taskDefinition' --output text)"
  running_image="$(aws ecs describe-task-definition --task-definition "$running_task_definition" \
    --query 'taskDefinition.containerDefinitions[0].image' --output text)"
  if [ "${running_image##*:}" != "$released_tag" ]; then
    echo "App deployment in flight: $service runs ${running_image##*:} but the released tag is $released_tag."
    echo "Re-run the infrastructure pipeline after the app pipeline finishes."
    exit 1
  fi
}

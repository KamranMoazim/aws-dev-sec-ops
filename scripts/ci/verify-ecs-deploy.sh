#!/usr/bin/env bash
# Usage: verify-ecs-deploy.sh <cluster> <service> <expected-image-tag>
# Confirms the service finished rolling out and its primary deployment runs the expected image.
set -euo pipefail

cluster="$1"
service="$2"
expected_tag="$3"

read -r rollout_state deployment_count task_definition < <(aws ecs describe-services \
  --cluster "$cluster" --services "$service" \
  --query 'services[0].[deployments[?status==`PRIMARY`].rolloutState | [0], length(deployments), deployments[?status==`PRIMARY`].taskDefinition | [0]]' \
  --output text)

image="$(aws ecs describe-task-definition --task-definition "$task_definition" \
  --query 'taskDefinition.containerDefinitions[0].image' --output text)"

echo "Primary deployment: rollout=$rollout_state deployments=$deployment_count image=${image##*/}"
if [ "$rollout_state" != "COMPLETED" ] || [ "$deployment_count" != "1" ]; then
  echo "Deployment verification failed: rollout not complete"
  exit 1
fi
if [ "${image##*:}" != "$expected_tag" ]; then
  echo "Deployment verification failed: expected tag $expected_tag"
  exit 1
fi
echo "Deployment verified: $service runs tag $expected_tag"

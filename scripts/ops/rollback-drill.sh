#!/usr/bin/env bash
# Usage: rollback-drill.sh <cluster> <service> <base-url>
# Deploys a revision that passes /health but returns 500 to users, sends traffic, and expects the
# 5xx alarm to roll the deployment back. The app image stays the same; only the command is overridden.
set -euo pipefail

cluster="$1"
service="$2"
base_url="$3"
timeout_seconds="${DRILL_TIMEOUT_SECONDS:-1200}"

broken_server="process.on('SIGTERM', () => process.exit(0));
require('http').createServer((req, res) => {
  const healthy = req.url === '/health';
  res.writeHead(healthy ? 200 : 500, { 'content-type': 'application/json' });
  res.end(healthy ? '{\"status\":\"ok\"}' : '{\"error\":\"rollback drill\"}');
}).listen(process.env.PORT || 3000);"

current_task_definition="$(aws ecs describe-services --cluster "$cluster" --services "$service" \
  --query 'services[0].taskDefinition' --output text)"

task_definition_file="$(mktemp)"
trap 'rm -f "$task_definition_file"' EXIT
aws ecs describe-task-definition --task-definition "$current_task_definition" --query 'taskDefinition' --output json \
  | jq --arg server "$broken_server" '.containerDefinitions[0].command = ["node", "-e", $server]
        | {family, taskRoleArn, executionRoleArn, networkMode, containerDefinitions, requiresCompatibilities,
           cpu, memory, runtimePlatform}' > "$task_definition_file"
broken_task_definition="$(aws ecs register-task-definition --cli-input-json "file://$task_definition_file" \
  --query 'taskDefinition.taskDefinitionArn' --output text)"

echo "Current revision: ${current_task_definition##*/}"
echo "Broken revision:  ${broken_task_definition##*/} (/health 200, everything else 500)"
aws ecs update-service --cluster "$cluster" --service "$service" \
  --task-definition "$broken_task_definition" --query 'service.serviceName' --output text >/dev/null

deadline=$((SECONDS + timeout_seconds))
while [ "$SECONDS" -lt "$deadline" ]; do
  for _ in $(seq 1 10); do
    curl -s -o /dev/null --max-time 5 "$base_url/" || true
  done
  read -r primary_task_definition rollout_state < <(aws ecs describe-services --cluster "$cluster" --services "$service" \
    --query 'services[0].deployments[?status==`PRIMARY`].[taskDefinition, rolloutState] | [0]' --output text)
  echo "$(date +%H:%M:%S) primary=${primary_task_definition##*/} rollout=$rollout_state"
  if [ "$primary_task_definition" = "$current_task_definition" ] && [ "$rollout_state" = "COMPLETED" ]; then
    echo "Drill passed: service rolled back to ${current_task_definition##*/}"
    aws ecs describe-services --cluster "$cluster" --services "$service" \
      --query 'services[0].deployments[?status==`PRIMARY`].rolloutStateReason | [0]' --output text
    exit 0
  fi
  if [ "$primary_task_definition" = "$broken_task_definition" ] && [ "$rollout_state" = "COMPLETED" ]; then
    echo "Drill failed: the broken revision completed without a rollback"
    exit 1
  fi
  sleep 5
done
echo "Drill failed: no rollback within ${timeout_seconds}s"
exit 1

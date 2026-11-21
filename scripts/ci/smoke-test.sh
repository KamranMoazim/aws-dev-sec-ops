#!/usr/bin/env bash
# Usage: smoke-test.sh <base-url>
# Checks the public endpoints; deployed image identity is verified separately (verify-ecs-deploy.sh).
set -euo pipefail

base_url="$1"
attempts=12

for attempt in $(seq 1 "$attempts"); do
  if curl -fsS --max-time 5 "$base_url/health" >/dev/null; then
    break
  fi
  echo "Attempt $attempt/$attempts: /health not ready"
  if [ "$attempt" -eq "$attempts" ]; then
    echo "Smoke test failed: /health never returned 200"
    exit 1
  fi
  sleep 5
done

curl -fsS --max-time 5 "$base_url/" | grep -Eq '"version":"[0-9]+\.[0-9]+\.[0-9]+'
curl -fsS --max-time 5 "$base_url/items" | grep -q '"count"'
echo "Smoke test passed for $base_url"

#!/usr/bin/env bash
# Usage: smoke-test.sh <base-url> <expected-commit>
# Retries because the load balancer can briefly route to draining tasks of the previous version.
set -euo pipefail

base_url="$1"
expected_commit="$2"
attempts=30

for attempt in $(seq 1 "$attempts"); do
  commit="$(curl -fsS --max-time 5 "$base_url/" | sed -n 's/.*"commit":"\([^"]*\)".*/\1/p' || true)"
  if [ "$commit" = "$expected_commit" ]; then
    break
  fi
  echo "Attempt $attempt/$attempts: got commit '${commit:-none}', want '$expected_commit'"
  if [ "$attempt" -eq "$attempts" ]; then
    echo "Smoke test failed: commit never matched"
    exit 1
  fi
  sleep 10
done

curl -fsS --max-time 5 "$base_url/health" >/dev/null
curl -fsS --max-time 5 "$base_url/items" | grep -q '"count"'
echo "Smoke test passed for commit $expected_commit"

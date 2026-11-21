#!/usr/bin/env bash
# Usage: smoke-test.sh <base-url> <expected-version>
# Retries because the load balancer can briefly route to draining tasks of the previous version.
set -euo pipefail

base_url="$1"
expected_version="$2"
attempts=30

for attempt in $(seq 1 "$attempts"); do
  version="$(curl -fsS --max-time 5 "$base_url/" | sed -n 's/.*"version":"\([^"]*\)".*/\1/p' || true)"
  if [ "$version" = "$expected_version" ]; then
    break
  fi
  echo "Attempt $attempt/$attempts: got version '${version:-none}', want '$expected_version'"
  if [ "$attempt" -eq "$attempts" ]; then
    echo "Smoke test failed: version never matched"
    exit 1
  fi
  sleep 10
done

curl -fsS --max-time 5 "$base_url/health" >/dev/null
curl -fsS --max-time 5 "$base_url/items" | grep -q '"count"'
echo "Smoke test passed for version $expected_version"

#!/usr/bin/env bash
# Runs every source scan, even after a failure, so one run shows all findings; exits non-zero if any failed.
set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
failed=()
for scan in secrets sast sca iac; do
  echo "==> scan-$scan"
  if ! "$script_dir/scan-$scan.sh"; then
    failed+=("$scan")
  fi
done

if [ ${#failed[@]} -gt 0 ]; then
  echo "Security gate FAILED: ${failed[*]}"
  exit 1
fi
echo "Security gate passed"

#!/usr/bin/env bash
# Usage: scan-dast.sh <base-url>
# OWASP ZAP baseline (passive) scan; fails on any WARN or FAIL not accepted in zap-baseline.conf.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$REPO_ROOT/scripts/security/versions.env"

target="$1"
chmod 777 "$REPORT_DIR"
docker run --rm -v "$REPORT_DIR:/zap/wrk:rw" -v "$REPO_ROOT/scripts/security/zap-baseline.conf:/zap/zap-baseline.conf:ro" \
  "ghcr.io/zaproxy/zaproxy:$ZAP_VERSION" \
  zap-baseline.py -t "$target" -c /zap/zap-baseline.conf -r zap-baseline.html -J zap-baseline.json

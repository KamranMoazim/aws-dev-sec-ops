#!/usr/bin/env bash
# Usage: scan-image.sh <image>
# Fails on fixable HIGH/CRITICAL vulnerabilities in a built image; run before pushing.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

image="$1"
trivy_args=(image --scanners vuln --severity HIGH,CRITICAL --ignore-unfixed --quiet "$image")
trivy "${trivy_args[@]}" --format template --template "@$TOOLS_DIR/share/trivy/junit.tpl" \
  --output "$REPORT_DIR/trivy-image.xml"
trivy "${trivy_args[@]}" --exit-code 1

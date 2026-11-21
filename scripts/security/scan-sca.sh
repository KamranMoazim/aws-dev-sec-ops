#!/usr/bin/env bash
# Fails on fixable HIGH/CRITICAL vulnerabilities in app dependencies (package-lock.json).
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

trivy_args=(fs --scanners vuln --severity HIGH,CRITICAL --ignore-unfixed --quiet app)
trivy "${trivy_args[@]}" --format template --template "@$TOOLS_DIR/share/trivy/junit.tpl" \
  --output "$REPORT_DIR/trivy-sca.xml"
trivy "${trivy_args[@]}" --exit-code 1

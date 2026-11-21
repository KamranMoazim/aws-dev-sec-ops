#!/usr/bin/env bash
# Fails on ERROR-severity Semgrep findings in app code and the Dockerfile.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

semgrep scan --metrics=off --error --severity ERROR \
  --config p/javascript --config p/nodejs --config p/dockerfile \
  --junit-xml-output="$REPORT_DIR/semgrep.xml" \
  app

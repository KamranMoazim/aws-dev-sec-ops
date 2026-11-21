#!/usr/bin/env bash
# Fails on any detected secret in the working tree.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

gitleaks dir . --config .gitleaks.toml --redact --no-banner --exit-code 1 \
  --report-format junit --report-path "$REPORT_DIR/gitleaks.xml"

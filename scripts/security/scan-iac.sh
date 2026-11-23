#!/usr/bin/env bash
# Fails on failed Checkov policies for Terraform and the Dockerfile; justified skips live inline in the code.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

checkov --quiet --compact --framework terraform dockerfile \
  -d infra -f app/Dockerfile \
  --output cli --output junitxml --output-file-path console,"$REPORT_DIR/checkov.xml"

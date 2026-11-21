#!/usr/bin/env bash
# Sourced by the scan scripts: puts pinned tools on PATH and prepares the report directory.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TOOLS_DIR="${TOOLS_DIR:-$REPO_ROOT/.tools}"
REPORT_DIR="${REPORT_DIR:-$REPO_ROOT/reports}"
export PATH="$TOOLS_DIR/bin:$PATH"
mkdir -p "$REPORT_DIR"
# ECR Public first: reliable from CodeBuild and avoids GHCR/GCR throttling; GCR mirror as fallback.
export TRIVY_DB_REPOSITORY="${TRIVY_DB_REPOSITORY:-public.ecr.aws/aquasecurity/trivy-db:2,mirror.gcr.io/aquasec/trivy-db:2}"
export TRIVY_TIMEOUT="${TRIVY_TIMEOUT:-15m}"
cd "$REPO_ROOT"

#!/usr/bin/env bash
# Usage: terraform-validate.sh
# Formatting, validation of every root without a backend, then the Checkov IaC gate.
source "$(dirname "${BASH_SOURCE[0]}")/terraform-common.sh"

terraform fmt -check -recursive -diff "$REPO_ROOT/infra"
for root in "$REPO_ROOT"/infra/aws/bootstrap "$REPO_ROOT"/infra/aws/envs/*/; do
  echo "==> validate ${root#"$REPO_ROOT"/}"
  terraform -chdir="$root" init -no-color -backend=false >/dev/null
  terraform -chdir="$root" validate -no-color
done
"$REPO_ROOT/scripts/security/scan-iac.sh"

#!/usr/bin/env bash
# Usage: terraform-apply.sh <environment> <plan-file>
# Applies exactly the approved plan; Terraform refuses it if the state changed after planning.
source "$(dirname "${BASH_SOURCE[0]}")/terraform-common.sh"

root="$REPO_ROOT/infra/aws/envs/$1"
cp "$2" "$root/tfplan"
terraform_init_backend "$root" >/dev/null
terraform -chdir="$root" apply -no-color -lock-timeout=5m tfplan

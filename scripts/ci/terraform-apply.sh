#!/usr/bin/env bash
# Usage: terraform-apply.sh <environment> <plan-dir>
# Applies exactly the approved plan. Terraform refuses it if its state changed after planning; this script
# also refuses it if an app release happened since, because the plan would roll the service back.
source "$(dirname "${BASH_SOURCE[0]}")/terraform-common.sh"

root="$REPO_ROOT/infra/aws/envs/$1"
plan_dir="$2"
cp "$plan_dir/tfplan" "$root/tfplan"
terraform_init_backend "$root" >/dev/null
current_tag="$(released_tag_when_idle "$root")"
planned_tag="$(cat "$plan_dir/released-tag.txt")"
if [ "$current_tag" != "$planned_tag" ]; then
  echo "Plan is stale: it was made for release ${planned_tag:-none}, the current release is ${current_tag:-none}." >&2
  echo "Re-run the infrastructure pipeline to plan against the current release." >&2
  exit 1
fi
terraform -chdir="$root" apply -no-color -lock-timeout=5m tfplan

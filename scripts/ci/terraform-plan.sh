#!/usr/bin/env bash
# Usage: terraform-plan.sh <environment>
# Writes tfplan, plan.txt and the released app tag the plan was based on into the environment root,
# and prints a one-line summary for the approver.
source "$(dirname "${BASH_SOURCE[0]}")/terraform-common.sh"

root="$REPO_ROOT/infra/aws/envs/$1"
terraform_init_backend "$root" >/dev/null
released_tag_when_idle "$root" > "$root/released-tag.txt"
terraform -chdir="$root" plan -no-color -lock-timeout=5m -out=tfplan
terraform -chdir="$root" show -no-color tfplan > "$root/plan.txt"
grep -Eo '^(Plan: .*|No changes\..*)' "$root/plan.txt" | head -1 > "$root/plan-summary.txt" || echo "No changes." > "$root/plan-summary.txt"
cat "$root/plan-summary.txt"

# Runbooks

| Runbook | Use when |
|---|---|
| [Release and approval](release-and-approval.md) | Shipping a version to staging and prod |
| [Rollback](rollback.md) | A deployment misbehaves or an alarm fires |
| [Infrastructure change](infrastructure-change.md) | Changing Terraform for a workload environment |
| [Secret rotation](secret-rotation.md) | Rotating the database password or reacting to a leak |
| [Onboarding a new service](onboard-new-service.md) | Adding a second container service |
| [Teardown and rebuild](teardown-and-rebuild.md) | Saving cost overnight or removing everything |

Commands assume the repo root, a `.env` with `TF_VAR_dns_zone_name`, `TF_VAR_approval_emails` and
`TF_VAR_alert_emails`, and AWS credentials for the account.

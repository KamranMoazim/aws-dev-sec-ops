# Security baseline

`infra/aws/envs/security` (module `security-baseline`) turns on account-wide detection and audit:

| Control | Setting |
|---|---|
| CloudTrail | Multi-region trail, log file validation, KMS, S3 + CloudWatch Logs |
| GuardDuty | Detector, S3 data events, Runtime Monitoring with the managed ECS Fargate agent |
| Security Hub | AWS Foundational Security Best Practices, consolidated control findings |
| AWS Config | All resource types, daily recording (Security Hub controls depend on it) |
| Alerts | EventBridge sends GuardDuty severity 7+ and new HIGH/CRITICAL Security Hub findings to SNS email |

Audit logs go to one KMS-encrypted bucket (TLS only, versioned, Glacier IR after 90 days). The
infrastructure pipeline is denied this root's state; it is applied by hand like `bootstrap` and `shared`.

In a new account, create the AWS Config service-linked role once before the first apply:
`aws iam create-service-linked-role --aws-service-name config.amazonaws.com`.

## Service control policies

Examples in [scp/](scp/), for an AWS Organization with separate workload accounts:

- `deny-leave-organization.json`: member accounts cannot leave the organization.
- `deny-unapproved-regions.json`: only us-east-1, except global services.
- `protect-security-baseline.json`: only a `SecurityAdmin` role can stop or delete CloudTrail,
  Config, GuardDuty or Security Hub.

They are not attached here: this project runs in the organization's management account, and SCPs
never apply to the management account. Attach them to the workload OU once dev, staging and prod
move to their own accounts.

## Check it works

```sh
aws guardduty create-sample-findings --detector-id "$(terraform -chdir=infra/aws/envs/security output -raw guardduty_detector_id)" \
  --finding-types 'Backdoor:EC2/C&CActivity.B!DNS'
```

The sample finding appears in GuardDuty, then in Security Hub, and severity 8 sends an alert email.

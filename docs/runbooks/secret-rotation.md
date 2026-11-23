# Secret rotation

The database master password is an RDS-managed secret in Secrets Manager, rotated every 7 days.

The app reads it at connection time (`DB_SECRET_ARN`), caches it for 5 minutes and drops the cache when
Postgres rejects it, so running tasks pick up a rotated password without a redeploy. Only the task role of
that environment can read the secret.

## Rotate now (suspected leak)

```sh
arn=$(terraform -chdir=infra/aws/envs/<env> output -raw db_secret_arn)
aws secretsmanager rotate-secret --secret-id "$arn"
aws secretsmanager describe-secret --secret-id "$arn" --query '[LastRotatedDate,NextRotationDate]'
curl -fsS https://<env-host>.<zone>/items
```

A few requests may fail while existing connections are replaced; they recover on the next connection.

## Check

- `aws secretsmanager describe-secret --secret-id "$arn" --query RotationEnabled` returns `true`.
- CloudTrail records `RotateSecret` and `GetSecretValue` calls (`devsecops-security` trail).

## Other secrets

Secrets added through the `secrets` module live under `devsecops-<env>/`, encrypted with the environment
KMS key. Rotate the value at its source, update the secret, then force a new deployment
(`aws ecs update-service --cluster devsecops-<env> --service <service> --force-new-deployment`) unless the
app reads it at runtime.

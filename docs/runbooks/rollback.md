# Rollback

## Automatic

Every service has three deployment alarms: target 5xx (5 or more per minute), unhealthy tasks, and p99
latency above 1.5 s for 3 minutes. If one fires while a deployment is in progress, including the blue/green
bake time, ECS rolls back to the previous revision. Tasks that never become healthy are rolled back by the
circuit breaker.

Confirm what happened:

```sh
aws ecs list-service-deployments --cluster devsecops-<env> --service hello-service --max-results 3
aws ecs describe-service-deployments --service-deployment-arns <arn> \
  --query 'serviceDeployments[0].[status,statusReason,alarms.triggeredAlarmNames]'
```

Alarms only roll back during a deployment. Detection takes about 3 minutes, which is why the bake is 5
minutes in staging and 10 in prod. Do not shorten the bake below that.

## Manual, after a deployment completed

1. Find the last good image tag: `aws ecr describe-images --repository-name hello-service` or the SSM
   parameter history `aws ssm get-parameter-history --name /devsecops/<env>/hello-service/image-tag`.
2. Point the service at the last good task definition revision:

```sh
aws ecs update-service --cluster devsecops-<env> --service hello-service \
  --task-definition devsecops-<env>-hello-service:<revision>
```

3. Record the tag so Terraform keeps it:
   `aws ssm put-parameter --name /devsecops/<env>/hello-service/image-tag --value <tag> --type String --overwrite`
4. Fix forward on a branch; the next release replaces the rollback.

## Prove it

`scripts/ops/rollback-drill.sh devsecops-staging hello-service https://staging.<zone>` deploys a revision
that passes `/health` but returns 500, sends traffic and expects ECS to roll back (about 6 minutes).

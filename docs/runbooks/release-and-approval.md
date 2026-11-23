# Release and approval

The release pipeline `devsecops-hello-service-release` builds once and promotes the same image:
staging (blue/green, smoke, OWASP ZAP) -> manual approval -> prod (blue/green, smoke).

## Before you start

- Staging and prod are created on demand: `make tf-plan ENV=staging && make tf-apply ENV=staging`, then the
  same for `prod` (about 15 minutes, RDS is the slow part).
- The approval email subscription must be confirmed once.

## Cut and ship a release

```sh
git checkout develop && git pull
git checkout -b release/0.3.0
(cd app && npm version minor --no-git-tag-version)
git commit -am "chore: Bump version to 0.3.0"
git push -u origin release/0.3.0
```

1. The push starts the pipeline. Staging gets the image, the smoke test and the ZAP baseline.
2. You receive an approval email. Check staging (`https://staging.<zone>/`), then approve or reject in the
   CodePipeline console (stage ApproveProd, Review). Approvals expire after 24 hours.
3. Prod deploys blue/green with a 10 minute bake. Alarms during the bake roll it back automatically.
4. After prod is healthy, merge and tag:

```sh
git checkout main && git pull && git merge --no-ff release/0.3.0 && git tag v0.3.0
git push origin main v0.3.0
git checkout develop && git merge --no-ff release/0.3.0 && git push origin develop
```

## Fixing a release

Commit the fix on the `release/*` branch and push; the pipeline runs again from the start. Back-merge the
fix into `develop` afterwards.

## When the ZAP gate fails

Read the warnings in the `DastBaseline` build log. Fix the app, or, if the rule does not apply, set it to
`IGNORE` in `scripts/security/zap-baseline.conf` with the reason after a tab. Never ignore a rule
without a reason.

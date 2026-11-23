# Onboarding a new service

The platform is built around one service, but every piece is a module.

1. App: a directory with a Dockerfile that has a `test` target, listens on `PORT` and serves `/health`.
2. Image repository: add a `module "ecr"` block in `envs/shared` for the new name.
3. Service: in `modules/app-environment`, add a second `module "ecs-service"` (own ALB or a listener rule
   on the existing one), its alarms come with the module.
4. Pipeline: add a `module "pipeline"` instance in `envs/shared` with `trigger_file_paths` for the new
   directory and the target environments; the security, build and smoke stages are reused.
5. Security: the same `scripts/security` gates run unchanged; extend `zap-baseline.conf` only with reasons.
6. Docs: update the architecture diagrams in `docs/architecture` and this runbook if anything differs.

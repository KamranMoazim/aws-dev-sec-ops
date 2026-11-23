# Infrastructure change

Workload environments (dev by default, see `infra_pipeline_environments` in `envs/shared`) change only
through the `devsecops-infra` pipeline.

1. Change Terraform on a `feature/*` branch. Run `terraform fmt -recursive infra` and `make tf-plan ENV=dev`
   locally to preview.
2. Merge into `develop`. The pipeline runs fmt, validate and Checkov, then plans with read-only credentials.
3. The approval email shows the plan summary, for example `dev: Plan: 0 to add, 1 to change, 0 to destroy`.
   The full plan is in the Plan build log. Approve only what you expect.
4. Apply runs exactly the approved plan.

The pipeline refuses to plan or apply while an app deployment is in flight, and refuses a plan made before
a newer app release ("Plan is stale"). Wait for the app pipeline, then start the infra pipeline again:
`aws codepipeline start-pipeline-execution --name devsecops-infra`.

Bootstrap, `envs/shared` (holds the pipelines) and `envs/security` are applied by hand with
`make tf-plan ENV=<root> && make tf-apply ENV=<root>`. The pipeline is denied their state.

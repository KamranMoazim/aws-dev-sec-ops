# Teardown and rebuild

## Order

Destroy in reverse dependency order: prod, staging, dev, security, shared, then bootstrap last.

```sh
make destroy-all
```

`destroy-all` destroys prod, staging, dev, security and shared in that order, asking for confirmation at
each step, and stops before bootstrap.

## Nightly cost saving

Destroy only the workloads and keep shared, security and bootstrap:

```sh
make tf-destroy ENV=prod && make tf-destroy ENV=staging && make tf-destroy ENV=dev
```

Rebuild dev with `make tf-plan ENV=dev && make tf-apply ENV=dev` (about 12 minutes).

## Destroying shared: things to redo afterwards

- The Route 53 zone is deleted. A new zone gets new name servers, so update the NS records at the
  registrar.
- The CodeConnections GitHub connection is deleted. After recreating it, complete the handshake in the
  console and choose the GitHub App installation.
- ECR images are deleted (`ecr_force_delete = true`).

## Destroying bootstrap

The state bucket has `prevent_destroy` and holds its own state. Only when nothing else remains:

1. Copy `infra/aws/bootstrap/backend.tf` aside and remove the `backend "s3"` block, then
   `terraform -chdir=infra/aws/bootstrap init -migrate-state` to move its state to a local file.
2. Remove `prevent_destroy` from the bucket, empty all object versions, and run
   `terraform -chdir=infra/aws/bootstrap destroy`.
3. Restore `backend.tf`.

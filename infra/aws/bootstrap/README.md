# Terraform bootstrap

One-time setup in the shared / CI-CD account. Creates what every other root module needs:

- S3 state bucket: versioned, SSE-KMS with a rotating CMK, public access blocked, TLS-only policy,
  old versions expire after 90 days, `prevent_destroy` on
- State locking via S3 native lockfile (`use_lockfile = true`, Terraform >= 1.10); no DynamoDB table
- Monthly AWS Budget with email alerts at 80% actual and 100% forecasted spend

All environments (dev, staging, prod, security) keep state in this one bucket under separate keys and
reach their own accounts through `assume_role` in the provider.

## First run (local state)

```sh
cd infra/aws/bootstrap
cp terraform.tfvars.example terraform.tfvars   # set budget_alert_emails
terraform init
terraform plan -out=tfplan
terraform apply tfplan
terraform output -raw backend_config > ../backend.hcl
```

## Move bootstrap state into the bucket

Commit the generated `backend.tf` afterwards; later runs then use remote state.

```sh
cat > backend.tf <<'EOF'
terraform {
  backend "s3" {
    key = "bootstrap/terraform.tfstate"
  }
}
EOF
terraform init -migrate-state -backend-config=../backend.hcl
rm -f terraform.tfstate terraform.tfstate.backup
```

## Using the backend from other root modules

```hcl
terraform {
  backend "s3" {
    key = "envs/dev/terraform.tfstate"
  }
}
```

```sh
terraform init -backend-config=../../backend.hcl
```

## Teardown

The bucket has `prevent_destroy`. Destroy every other root module first, then remove the
`lifecycle` block, empty the bucket (all versions) and run `terraform destroy`.

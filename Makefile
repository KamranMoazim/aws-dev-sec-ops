.PHONY: install test lint format build up down smoke

install:
	cd app && npm ci

test:
	cd app && npm test

lint:
	cd app && npm run lint && npm run format:check

format:
	cd app && npm run format

build:
	docker build -t hello-service:local --build-arg APP_COMMIT=$$(git rev-parse --short HEAD) app

up:
	docker compose up -d --build --wait

down:
	docker compose down -v

smoke:
	curl -fsS localhost:3000/health && echo && curl -fsS localhost:3000/items && echo

-include .env
export TF_VAR_dns_zone_name TF_VAR_approval_emails

ENV ?= dev
TF_DIR = infra/aws/envs/$(ENV)

.PHONY: tf-init tf-plan tf-apply tf-destroy tf-check

tf-init:
	terraform -chdir=$(TF_DIR) init -input=false -backend-config=../../backend.hcl

tf-plan: tf-init
	terraform -chdir=$(TF_DIR) plan -input=false -out=tfplan

tf-apply:
	terraform -chdir=$(TF_DIR) apply -input=false tfplan

tf-destroy: tf-init
	terraform -chdir=$(TF_DIR) destroy -input=false

tf-check:
	terraform fmt -check -recursive infra
	docker run --rm -v "$$PWD/infra:/infra" bridgecrew/checkov:latest -d /infra --framework terraform --compact --quiet

IMAGE_TAG ?= $(shell git rev-parse --short HEAD)
ECR_URL = $(shell terraform -chdir=infra/aws/envs/shared output -raw ecr_repository_url)

.PHONY: push

push:
	aws ecr get-login-password | docker login --username AWS --password-stdin $(firstword $(subst /, ,$(ECR_URL)))
	docker build --platform linux/amd64 --provenance=false --sbom=false --build-arg APP_COMMIT=$(IMAGE_TAG) -t $(ECR_URL):$(IMAGE_TAG) app
	docker push $(ECR_URL):$(IMAGE_TAG)

SCAN_IMAGE = public.ecr.aws/docker/library/python:3.12

.PHONY: security-scan

# Runs the CI security gate in Linux, matching CodeBuild; tools are cached in .tools-linux.
security-scan:
	docker run --rm --platform linux/amd64 -v "$$PWD:/src" -w /src -e TOOLS_DIR=/src/.tools-linux $(SCAN_IMAGE) \
		bash -c 'scripts/security/install-tools.sh && scripts/security/scan-source.sh'

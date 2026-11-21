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
	docker build -t hello-service:local --build-arg APP_VERSION=$$(git rev-parse --short HEAD) app

up:
	docker compose up -d --build --wait

down:
	docker compose down -v

smoke:
	curl -fsS localhost:3000/health && echo && curl -fsS localhost:3000/items && echo

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

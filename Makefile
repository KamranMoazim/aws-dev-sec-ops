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

.DEFAULT_GOAL := help
SHELL := /bin/bash

.PHONY: help test lint build run helm-lint

help: ## Lista comandos disponíveis para este microsserviço
	@grep -E '^[a-zA-Z0-9_-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

test: ## Executa testes unitários com pytest e cobertura mínima de 90%
	docker run --rm -e PYTHONDONTWRITEBYTECODE=1 -e COVERAGE_FILE=/tmp/.coverage \
		-v "$$PWD/app:/app:ro" -w /app python:3.12-slim-bookworm \
		sh -c "pip install -q --no-cache-dir -r requirements-dev.txt && pytest -v -o cache_dir=/tmp/pytest_cache --cov=src --cov-fail-under=90"

lint: ## Executa linter Ruff no código Python
	docker run --rm -v "$$PWD/app:/app:ro" -w /app ghcr.io/astral-sh/ruff:0.9.2 check --no-cache src tests

build: ## Constrói a imagem Docker localmente com hardening de produção
	docker build -t {{SERVICE_NAME}}:latest app/

run: build ## Executa o contêiner na porta configurada
	docker run --rm -p {{SERVICE_PORT}}:{{SERVICE_PORT}} --name {{SERVICE_NAME}} {{SERVICE_NAME}}:latest

helm-lint: ## Valida a sintaxe e renderização do Helm Chart
	helm lint helm/
	helm template test-release helm/

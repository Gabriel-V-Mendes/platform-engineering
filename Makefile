.DEFAULT_GOAL := help
SHELL := /bin/bash

.PHONY: help up down restart ps logs test lint new-service verify secrets docs

help: ## Lista todos os comandos disponíveis na plataforma
	@grep -E '^[a-zA-Z0-9_-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

up: ## Sobe a plataforma IDP (Portal MkDocs + Microsserviço de Referência) com 1 comando
	docker compose up -d --build --wait

down: ## Derruba todos os containers da plataforma
	docker compose down $(V)

restart: down up ## Reinicia a plataforma limpa

ps: ## Exibe o status e healthchecks dos containers da plataforma
	docker compose ps

logs: ## Exibe logs em tempo real do portal IDP e do serviço demo
	docker compose logs -f

test: ## Executa a suíte de testes automatizados da aplicação template (>90% cobertura)
	docker run --rm -e PYTHONDONTWRITEBYTECODE=1 -e COVERAGE_FILE=/tmp/.coverage \
		-v "$$PWD/templates/microservice/app:/app:ro" -w /app python:3.12-slim-bookworm \
		sh -c "pip install -q --no-cache-dir -r requirements-dev.txt && pytest -v -o cache_dir=/tmp/pytest_cache --cov=src --cov-fail-under=90"

lint: ## Valida qualidade Python (Ruff), Terraform (fmt/validate) e Helm (lint)
	docker run --rm -v "$$PWD/templates/microservice/app:/app:ro" -w /app ghcr.io/astral-sh/ruff:0.9.2 check --no-cache src tests
	cd terraform/modules/microservice-infra && terraform init -backend=false >/dev/null && terraform fmt -check && terraform validate
	cd terraform/examples/consumer-service && terraform init -backend=false >/dev/null && terraform fmt -check && terraform validate
	helm lint templates/microservice/helm

new-service: ## Cria um novo microsserviço a partir do Golden Path (ex: make new-service NAME=pagamentos PORT=8080 OWNER=team-checkout)
	chmod +x ./scripts/new-service.sh
	./scripts/new-service.sh $(if $(NAME),--name $(NAME),) $(if $(PORT),--port $(PORT),) $(if $(OWNER),--owner $(OWNER),) $(if $(DESC),--desc "$(DESC)",)

verify: ## Executa a validação cronometrada do Golden Path (Criação + Build + Deploy + Probes em < 30 minutos)
	chmod +x ./scripts/verify-golden-path.sh
	./scripts/verify-golden-path.sh

docs: ## Compila a documentação do MkDocs em modo estático com validação de links
	docker run --rm -v "$$PWD:/docs" squidfunk/mkdocs-material:9.5.49 build --strict

secrets: ## Varre todo o histórico Git com Gitleaks em busca de segredos vazados
	docker run --rm -v "$$PWD:/repo" ghcr.io/gitleaks/gitleaks:v8.30.1 git /repo --redact --verbose --exit-code 1

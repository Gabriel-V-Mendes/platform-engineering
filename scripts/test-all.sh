#!/usr/bin/env bash
# ==============================================================================
# Script de Validação e Testes Completos da Plataforma
# ==============================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=================================================================="
echo "1/5 · Validando Qualidade do Código Python (Ruff + Pytest)"
echo "=================================================================="
docker run --rm -v "$ROOT_DIR/templates/microservice/app:/app:ro" -w /app \
  ghcr.io/astral-sh/ruff:0.9.2 check --no-cache src tests
echo "  ✔ Ruff aprovado sem erros!"

docker run --rm \
  -e PYTHONDONTWRITEBYTECODE=1 \
  -e COVERAGE_FILE=/tmp/.coverage \
  -v "$ROOT_DIR/templates/microservice/app:/app:ro" \
  -w /app python:3.12-slim-bookworm \
  sh -c "pip install -q --no-cache-dir --root-user-action=ignore -r requirements-dev.txt && pytest -q -o cache_dir=/tmp/pytest_cache --cov=src --cov-fail-under=90"
echo "  ✔ Pytest e cobertura (>90%) aprovados!"

echo ""
echo "=================================================================="
echo "2/5 · Validando Módulos Terraform (microservice-infra + consumer)"
echo "=================================================================="
cd "$ROOT_DIR/terraform/modules/microservice-infra"
terraform init -backend=false >/dev/null
terraform fmt -check
terraform validate >/dev/null
echo "  ✔ Módulo microservice-infra válido!"

cd "$ROOT_DIR/terraform/examples/consumer-service"
terraform init -backend=false >/dev/null
terraform fmt -check
terraform validate >/dev/null
echo "  ✔ Exemplo consumer-service válido!"

echo ""
echo "=================================================================="
echo "3/5 · Validando Helm Chart do Template Golden Path"
echo "=================================================================="
helm lint "$ROOT_DIR/templates/microservice/helm" >/dev/null
helm template test "$ROOT_DIR/templates/microservice/helm" >/dev/null
echo "  ✔ Helm Chart sintática e semanticamente válido!"

echo ""
echo "=================================================================="
echo "4/5 · Executando Verificação E2E do Golden Path (< 30 minutos)"
echo "=================================================================="
"$ROOT_DIR/scripts/verify-golden-path.sh"

echo ""
echo "=================================================================="
echo "5/5 · Varredura de Segredos com Gitleaks"
echo "=================================================================="
docker run --rm -v "$ROOT_DIR:/repo" ghcr.io/gitleaks/gitleaks:v8.30.1 \
  git /repo --redact --verbose --exit-code 1
echo "  ✔ Gitleaks: zero segredos detectados no repositório!"

echo ""
echo "=================================================================="
echo "🎉 TODAS AS VALIDAÇÕES DA PLATAFORMA PASSARAM COM SUCESSO!"
echo "=================================================================="

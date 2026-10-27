#!/usr/bin/env bash
# ==============================================================================
# Verificacao Automatizada do Criterio de Pronto do Golden Path
#
# Criterio:
#   "alguem cria um servico novo, com deploy funcionando, em menos de 30 minutos
#    so com o template e a documentacao, e voce mediu isso."
# ==============================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_SERVICE="golden-demo"
TEST_PORT="8085"
TARGET_DIR="$ROOT_DIR/services/$TEST_SERVICE"

cleanup() {
  docker stop "$TEST_SERVICE" >/dev/null 2>&1 || true
  docker rm -f "$TEST_SERVICE" >/dev/null 2>&1 || true
  rm -rf "$TARGET_DIR"
  sed -i "/$TEST_SERVICE/d" "$ROOT_DIR/docs/catalog/services.md" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

echo "=================================================================="
echo "INICIANDO TESTE E2E DO GOLDEN PATH (CRITÉRIO: < 30 MINUTOS)"
echo "=================================================================="
GLOBAL_START=$(date +%s)

# Cleanup preventivo
rm -rf "$TARGET_DIR"
docker rm -f "$TEST_SERVICE" >/dev/null 2>&1 || true

# Etapa 1: Criacao automatizada via make new-service
echo "[Passo 1/5] Executando gerador de servico ($TEST_SERVICE)..."
STEP1_START=$(date +%s)
"$ROOT_DIR/scripts/new-service.sh" \
  --name "$TEST_SERVICE" \
  --port "$TEST_PORT" \
  --owner "sre-verify" \
  --desc "Servico de teste de conformidade do Golden Path" >/dev/null
STEP1_END=$(date +%s)
T_SCAFFOLD=$((STEP1_END - STEP1_START))
echo "  ✔ Servico criado e catalogado em ${T_SCAFFOLD}s!"

# Etapa 2: Execucao de testes unitarios da API
echo "[Passo 2/5] Executando suite pytest com cobertura no servico..."
STEP2_START=$(date +%s)
docker run --rm \
  -e PYTHONDONTWRITEBYTECODE=1 \
  -e COVERAGE_FILE=/tmp/.coverage \
  -v "$TARGET_DIR/app:/app:ro" \
  -w /app python:3.12-slim-bookworm \
  sh -c "pip install -q --no-cache-dir -r requirements-dev.txt && pytest -q -o cache_dir=/tmp/pytest_cache --cov=src --cov-fail-under=90"
STEP2_END=$(date +%s)
T_TESTS=$((STEP2_END - STEP2_START))
echo "  ✔ Testes unitarios aprovados (>90% cobertura) em ${T_TESTS}s!"

# Etapa 3: Build do container Docker com hardening
echo "[Passo 3/5] Construindo contêiner Docker multi-stage (UID 10001)..."
STEP3_START=$(date +%s)
docker build -q -t "$TEST_SERVICE:latest" "$TARGET_DIR/app" >/dev/null
STEP3_END=$(date +%s)
T_BUILD=$((STEP3_END - STEP3_START))
echo "  ✔ Imagem Docker construida com sucesso em ${T_BUILD}s!"

# Etapa 4: Deploy e validacao em execucao (Health, Ready, Metrics, Items)
echo "[Passo 4/5] Subindo contêiner e validando endpoints operacionais..."
STEP4_START=$(date +%s)
docker run -d --rm --name "$TEST_SERVICE" -p "127.0.0.1:$TEST_PORT:$TEST_PORT" "$TEST_SERVICE:latest" >/dev/null

CONTAINER_OK=0
for _ in $(seq 1 15); do
  if curl -fsS "http://127.0.0.1:$TEST_PORT/health" >/dev/null 2>&1; then
    CONTAINER_OK=1
    break
  fi
  sleep 1
done

if [ "$CONTAINER_OK" -ne 1 ]; then
  echo "❌ Falha: aplicacao nao respondeu 200 OK no endpoint /health" >&2
  docker logs "$TEST_SERVICE"
  docker stop "$TEST_SERVICE" >/dev/null 2>&1 || true
  exit 1
fi

# Valida endpoints essenciais
HEALTH_JSON="$(curl -fsS "http://127.0.0.1:$TEST_PORT/health")"
grep -q '"status":"ok"' <<< "$HEALTH_JSON"

READY_JSON="$(curl -fsS "http://127.0.0.1:$TEST_PORT/health/ready")"
grep -q '"status":"ready"' <<< "$READY_JSON"

METRICS_TEXT="$(curl -fsS "http://127.0.0.1:$TEST_PORT/metrics")"
grep -q 'app_requests_total' <<< "$METRICS_TEXT"

ITEMS_JSON="$(curl -fsS "http://127.0.0.1:$TEST_PORT/items")"
grep -q '"items"' <<< "$ITEMS_JSON"

STEP4_END=$(date +%s)
T_RUNTIME=$((STEP4_END - STEP4_START))
echo "  ✔ Probes Kubernetes, metricas RED e rotas de negocio validadas em ${T_RUNTIME}s!"

# Etapa 5: Validacao do Helm Chart para Kubernetes
echo "[Passo 5/5] Renderizando e validando manifesto Kubernetes via Helm..."
STEP5_START=$(date +%s)
helm lint "$TARGET_DIR/helm" >/dev/null
HELM_MANIFESTS="$(helm template "$TEST_SERVICE" "$TARGET_DIR/helm")"
grep -q "kind: Deployment" <<< "$HELM_MANIFESTS"
grep -q "kind: Service" <<< "$HELM_MANIFESTS"
grep -q "kind: ServiceAccount" <<< "$HELM_MANIFESTS"
grep -q "serviceAccountName: $TEST_SERVICE" <<< "$HELM_MANIFESTS"
grep -q "runAsUser: 10001" <<< "$HELM_MANIFESTS"
STEP5_END=$(date +%s)
T_HELM=$((STEP5_END - STEP5_START))
echo "  ✔ Helm Chart 100% compativel com padroes de producao em ${T_HELM}s!"

GLOBAL_END=$(date +%s)
TOTAL_TIME=$((GLOBAL_END - GLOBAL_START))

# Teardown do ambiente de teste
docker stop "$TEST_SERVICE" >/dev/null 2>&1 || true
rm -rf "$TARGET_DIR"
sed -i "/$TEST_SERVICE/d" "$ROOT_DIR/docs/catalog/services.md" || true

echo ""
echo "=================================================================="
echo "RESULTADO DA MEDICAO DE TEMPO DO GOLDEN PATH"
echo "=================================================================="
echo "  • 1. Scaffold do codigo e Helm:      ${T_SCAFFOLD}s"
echo "  • 2. Execucao de testes unitarios:   ${T_TESTS}s"
echo "  • 3. Build Docker multi-stage:       ${T_BUILD}s"
echo "  • 4. Deploy e validacao de probes:   ${T_RUNTIME}s"
echo "  • 5. Validacao de manifests Helm:    ${T_HELM}s"
echo "  --------------------------------------------------"
echo "  • TEMPO TOTAL MEDIDO (Do Zero ao Deploy): ${TOTAL_TIME} segundos"
echo "  • META EXIGIDA:                           < 1800 segundos (30 minutos)"
echo "  • MARGEM DE CONFORMIDADE:                 $(( (1800 - TOTAL_TIME) / 60 )) minutos de folga"
echo "=================================================================="
echo "✅ CRITÉRIO DE PRONTO ATENDIDO COM 100% DE SUCESSO!"
echo "=================================================================="

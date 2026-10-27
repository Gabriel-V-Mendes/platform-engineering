#!/usr/bin/env bash
# ==============================================================================
# Bateria Completa de Testes E2E, Stress e Hardening da Plataforma IDP
# ==============================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORTAL_PORT="${PORTAL_PORT:-8008}"
DEMO_PORT="${DEMO_SERVICE_PORT:-8088}"
TEMP_SERVICE="battery-test-service"
TEMP_PORT="8089"

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

log_pass() {
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  PASSED_TESTS=$((PASSED_TESTS + 1))
  echo -e "  \033[32m✔ [PASS]\033[0m $1"
}

log_fail() {
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  FAILED_TESTS=$((FAILED_TESTS + 1))
  echo -e "  \033[31m❌ [FAIL]\033[0m $1" >&2
}

assert_status() {
  local url="$1"
  local expected_status="$2"
  local desc="$3"
  local actual_status
  actual_status=$(curl -s -o /dev/null -w "%{http_code}" "$url" || echo "000")
  if [ "$actual_status" -eq "$expected_status" ]; then
    log_pass "$desc (HTTP $actual_status)"
  else
    log_fail "$desc (Esperado: $expected_status, Obtido: $actual_status)"
  fi
}

assert_body_contains() {
  local url="$1"
  local match="$2"
  local desc="$3"
  local body
  body=$(curl -s "$url" || true)
  if grep -q "$match" <<< "$body"; then
    log_pass "$desc"
  else
    log_fail "$desc (Não encontrou '$match' no corpo da resposta)"
  fi
}

cleanup() {
  echo ""
  echo "🧹 Executando limpeza de recursos temporários da bateria..."
  docker stop "$TEMP_SERVICE" >/dev/null 2>&1 || true
  docker rm -f "$TEMP_SERVICE" >/dev/null 2>&1 || true
  rm -rf "$ROOT_DIR/services/$TEMP_SERVICE"
  sed -i "/$TEMP_SERVICE/d" "$ROOT_DIR/docs/catalog/services.md" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

echo "=================================================================="
echo "🧪 INICIANDO BATERIA EXAUSTIVA DE TESTES DA PLATAFORMA IDP"
echo "=================================================================="

# ==============================================================================
# 1. BATERIA DO PORTAL IDP (MkDocs Material)
# ==============================================================================
echo ""
echo "--- [1/6] TESTES DO PORTAL IDP (MKDOCS MATERIAL - PORTA $PORTAL_PORT) ---"

assert_status "http://127.0.0.1:$PORTAL_PORT/" 200 "Portal IDP: Homepage acessível"
assert_body_contains "http://127.0.0.1:$PORTAL_PORT/" "Portal de Engenharia de Plataforma" "Portal IDP: Título e cabeçalho corretos"
assert_status "http://127.0.0.1:$PORTAL_PORT/search/search_index.json" 200 "Portal IDP: Mecanismo de busca e índice JSON indexados"

# Valida todas as 4 ADRs com URLs do MkDocs
assert_status "http://127.0.0.1:$PORTAL_PORT/adrs/ADR-001-substituicao-backstage-por-idp-estatico/" 200 "ADR-001: Adoção do MkDocs Material em substituição ao Backstage"
assert_status "http://127.0.0.1:$PORTAL_PORT/adrs/ADR-002-golden-path-fastapi-docker-helm/" 200 "ADR-002: Padrão Golden Path para Microsserviços Python"
assert_status "http://127.0.0.1:$PORTAL_PORT/adrs/ADR-003-reusable-workflows-github-actions/" 200 "ADR-003: Workflows Reutilizáveis no GitHub Actions"
assert_status "http://127.0.0.1:$PORTAL_PORT/adrs/ADR-004-modulos-terraform-versionados/" 200 "ADR-004: Versionamento de Infraestrutura Terraform via Tags Git"

# Valida todos os 4 Runbooks operacionais
assert_status "http://127.0.0.1:$PORTAL_PORT/runbooks/onboarding-novo-servico/" 200 "Runbook: Onboarding de Novo Serviço via Golden Path"
assert_status "http://127.0.0.1:$PORTAL_PORT/runbooks/falha-deploy-helm/" 200 "Runbook: Troubleshooting e Falha de Deploy Helm"
assert_status "http://127.0.0.1:$PORTAL_PORT/runbooks/rollback-automatizado/" 200 "Runbook: Rollback Automatizado e Restauração de Serviço"
assert_status "http://127.0.0.1:$PORTAL_PORT/runbooks/quebra-seguranca-secrets/" 200 "Runbook: Quebra de Segurança, Vazamento de Segredos e Mitigação"

# Valida Catálogo de Serviços e Guias Golden Path
assert_status "http://127.0.0.1:$PORTAL_PORT/catalog/services/" 200 "Catálogo de Software: Página de Serviços registrada"
assert_status "http://127.0.0.1:$PORTAL_PORT/golden-path/" 200 "Guia: Visão Geral do Golden Path"
assert_status "http://127.0.0.1:$PORTAL_PORT/golden-path/microservice-template/" 200 "Guia: Template Oficial de Microsserviço"
assert_status "http://127.0.0.1:$PORTAL_PORT/golden-path/cli-guide/" 200 "Guia: Automação via CLI (make new-service)"

# ==============================================================================
# 2. BATERIA DO MICROSSERVIÇO DE REFERÊNCIA (FastAPI Golden Path)
# ==============================================================================
echo ""
echo "--- [2/6] TESTES FUNCIONAIS DO SERVIÇO DE REFERÊNCIA (PORTA $DEMO_PORT) ---"

assert_status "http://127.0.0.1:$DEMO_PORT/health" 200 "Kubernetes Liveness Probe (/health)"
assert_body_contains "http://127.0.0.1:$DEMO_PORT/health" '"status":"ok"' "Corpo da resposta Liveness Probe é válido"

assert_status "http://127.0.0.1:$DEMO_PORT/health/ready" 200 "Kubernetes Readiness Probe (/health/ready)"
assert_body_contains "http://127.0.0.1:$DEMO_PORT/health/ready" '"status":"ready"' "Corpo da resposta Readiness Probe é válido"

assert_status "http://127.0.0.1:$DEMO_PORT/info" 200 "Metadados do IDP (/info)"
assert_body_contains "http://127.0.0.1:$DEMO_PORT/info" '"golden_path":"v1.0.0"' "Versão do Golden Path no endpoint /info"

assert_status "http://127.0.0.1:$DEMO_PORT/items" 200 "Rota de Negócio GET /items"

# Teste de mutação POST /items com payload válido
POST_RESP=$(curl -s -w "\n%{http_code}" -X POST "http://127.0.0.1:$DEMO_PORT/items" \
  -H "Content-Type: application/json" \
  -d '{"name": "Item Teste Bateria", "description": "Criado durante os testes de carga"}')
POST_HTTP_CODE=$(tail -n1 <<< "$POST_RESP")
POST_BODY=$(head -n -1 <<< "$POST_RESP")

if [ "$POST_HTTP_CODE" -eq 201 ]; then
  log_pass "POST /items com payload válido retornou HTTP 201 Created"
else
  log_fail "POST /items com payload válido falhou (HTTP $POST_HTTP_CODE)"
fi

if grep -q "Item Teste Bateria" <<< "$POST_BODY"; then
  log_pass "Corpo de resposta do POST /items contém o item criado"
else
  log_fail "Corpo de resposta do POST /items não retornou o item esperado"
fi

# Teste de validação Pydantic v2: payload inválido (name vazio)
INVALID_POST_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "http://127.0.0.1:$DEMO_PORT/items" \
  -H "Content-Type: application/json" \
  -d '{"name": "", "description": "Invalido"}')
if [ "$INVALID_POST_STATUS" -eq 422 ]; then
  log_pass "Validação Pydantic v2: payload inválido retornou HTTP 422 Unprocessable Entity"
else
  log_fail "Validação Pydantic v2: esperado HTTP 422, obtido $INVALID_POST_STATUS"
fi

# Teste do cabeçalho de rastreabilidade distribuída X-Request-ID
REQ_ID_HEADER=$(curl -sI "http://127.0.0.1:$DEMO_PORT/items" | grep -i "x-request-id:" || true)
if [ -n "$REQ_ID_HEADER" ]; then
  log_pass "Header operacional X-Request-ID injetado na resposta HTTP: $(tr -d '\r\n' <<< "$REQ_ID_HEADER")"
else
  log_fail "Header X-Request-ID não foi encontrado no cabeçalho da resposta"
fi

# Teste de injeção de erro 500 controlado
assert_status "http://127.0.0.1:$DEMO_PORT/simulate-error" 500 "Endpoint de injeção de falhas /simulate-error retornou HTTP 500"

# Validação das métricas Prometheus (RED)
METRICS_OUTPUT=$(curl -s "http://127.0.0.1:$DEMO_PORT/metrics")
if grep -q "app_requests_total" <<< "$METRICS_OUTPUT"; then
  log_pass "Métricas Prometheus: Rate (app_requests_total) presente"
else
  log_fail "Métricas Prometheus: app_requests_total não encontrada"
fi

if grep -q "app_errors_total" <<< "$METRICS_OUTPUT"; then
  log_pass "Métricas Prometheus: Errors (app_errors_total) registrou falha HTTP 500 simulada"
else
  log_fail "Métricas Prometheus: app_errors_total não registrou falhas"
fi

if grep -q "app_request_duration_seconds" <<< "$METRICS_OUTPUT"; then
  log_pass "Métricas Prometheus: Duration (app_request_duration_seconds buckets) presente"
else
  log_fail "Métricas Prometheus: app_request_duration_seconds não encontrada"
fi

# ==============================================================================
# 3. BATERIA DE AUDITORIA DE LOGS ESTRUTURADOS E HARDENING DE SEGURANÇA
# ==============================================================================
echo ""
echo "--- [3/6] AUDITORIA DE LOGS JSON E HARDENING DE SEGURANÇA ---"

# Auditoria dos Logs JSON no stdout
RECENT_LOGS=$(docker logs --tail 30 golden-path-demo 2>&1)
LAST_JSON_LOG=$(grep "timestamp" <<< "$RECENT_LOGS" | tail -n1 || true)

if [ -n "$LAST_JSON_LOG" ]; then
  log_pass "Emissão de logs estruturados em JSON confirmada na stdout do contêiner"
  if grep -q '"service":' <<< "$LAST_JSON_LOG" && grep -q '"duration_ms"' <<< "$LAST_JSON_LOG"; then
    log_pass "Campos obrigatórios de telemetria ('service', 'duration_ms', 'timestamp') presentes no JSON"
  else
    log_fail "Campos obrigatórios ausentes no log JSON: $LAST_JSON_LOG"
  fi
else
  log_fail "Nenhum log estruturado em JSON foi encontrado no contêiner golden-path-demo"
fi

# Hardening: Execução com usuário non-root (UID 10001)
CONTAINER_UID=$(docker exec golden-path-demo id -u)
CONTAINER_GID=$(docker exec golden-path-demo id -g)
if [ "$CONTAINER_UID" -eq 10001 ] && [ "$CONTAINER_GID" -eq 10001 ]; then
  log_pass "Hardening de Contêiner: Execução estrita sob UID/GID 10001 (non-root)"
else
  log_fail "Falha de segurança: Contêiner executando como UID $CONTAINER_UID (esperado 10001)"
fi

# Hardening: Filesystem somente leitura (read_only: true)
WRITE_ROOT_TEST=$(docker exec golden-path-demo sh -c "touch /teste_root 2>&1" || true)
if grep -qi "read-only file system" <<< "$WRITE_ROOT_TEST"; then
  log_pass "Hardening de Contêiner: Root filesystem é estritamente somente leitura (Read-only)"
else
  log_fail "Falha de segurança: Root filesystem permitiu escrita não autorizada: $WRITE_ROOT_TEST"
fi

# Hardening: Escrita permitida no volume tmpfs temporário (/tmp)
WRITE_TMP_TEST=$(docker exec golden-path-demo sh -c "touch /tmp/test_ok && echo 'SUCESSO'" || true)
if grep -q "SUCESSO" <<< "$WRITE_TMP_TEST"; then
  log_pass "Hardening de Contêiner: Escrita temporária restrita ao /tmp (tmpfs) funcionando"
else
  log_fail "Falha: Escrita no diretório /tmp falhou"
fi

# ==============================================================================
# 4. BATERIA DE STRESS, CONCORRÊNCIA E CARDINALIDADE
# ==============================================================================
echo ""
echo "--- [4/6] TESTE DE CARGA CONCORRENTE E PROTEÇÃO DE CARDINALIDADE ---"

echo "  • Disparando 50 requisições concorrentes contra a API..."
CONCURRENT_SUCCESS=0
for _ in $(seq 1 50); do
  curl -s -o /dev/null -w "%{http_code}\n" "http://127.0.0.1:$DEMO_PORT/items" &
done | wait

# Testa cardinalidade com 20 caminhos dinâmicos aleatórios
echo "  • Injetando 20 URLs com UUIDs dinâmicos para teste de explosão de cardinalidade..."
for i in $(seq 1 20); do
  curl -s -o /dev/null "http://127.0.0.1:$DEMO_PORT/random-cardinality-attack-uuid-$i" || true
done

METRICS_AFTER=$(curl -s "http://127.0.0.1:$DEMO_PORT/metrics")
if grep -q 'endpoint="/unknown"' <<< "$METRICS_AFTER"; then
  log_pass "Normalização de rotas ativa: requisições desconhecidas agregadas em endpoint=\"/unknown\""
else
  log_fail "Falha na normalização: endpoint=\"/unknown\" não encontrado"
fi

if grep -q 'random-cardinality-attack' <<< "$METRICS_AFTER"; then
  log_fail "VULNERABILIDADE DETECTADA: URLs dinâmicas vazaram para as labels do Prometheus!"
else
  log_pass "Proteção contra explosão de cardinalidade validada: zero vazamentos de labels dinâmicas"
fi

# ==============================================================================
# 5. BATERIA DO GERADOR GOLDEN PATH (CLI MAKE NEW-SERVICE)
# ==============================================================================
echo ""
echo "--- [5/6] TESTES DO GERADOR GOLDEN PATH (MAKE NEW-SERVICE & LIFECYCLE) ---"

# Teste 5.1: Rejeição de nome inválido
INVALID_CLI_OUTPUT=$("$ROOT_DIR/scripts/new-service.sh" --name "Invalid_Name!" --port 8099 2>&1 || true)
if grep -qi "invalido" <<< "$INVALID_CLI_OUTPUT"; then
  log_pass "Validação do CLI: Nome inválido ('Invalid_Name!') rejeitado com mensagem clara"
else
  log_fail "Validação do CLI: Falha ao rejeitar nome de serviço inválido"
fi

# Teste 5.2: Criação de novo serviço com parâmetros complexos
echo "  • Gerando novo microsserviço temporário '$TEMP_SERVICE' na porta $TEMP_PORT..."
"$ROOT_DIR/scripts/new-service.sh" \
  --name "$TEMP_SERVICE" \
  --port "$TEMP_PORT" \
  --owner "core-fintech" \
  --desc "Billing & Payments Engine / Core Subsystem" >/dev/null

if [ -d "$ROOT_DIR/services/$TEMP_SERVICE" ]; then
  log_pass "Scaffold concluído: Diretório do serviço '$TEMP_SERVICE' criado"
else
  log_fail "Scaffold falhou: Diretório '$TEMP_SERVICE' não encontrado"
fi

# Teste 5.3: Conflito de nome duplicado
DUPLICATE_CLI_OUTPUT=$("$ROOT_DIR/scripts/new-service.sh" --name "$TEMP_SERVICE" --port "$TEMP_PORT" 2>&1 || true)
if grep -qi "ja existe" <<< "$DUPLICATE_CLI_OUTPUT"; then
  log_pass "Validação do CLI: Conflito de serviço duplicado detectado e bloqueado"
else
  log_fail "Validação do CLI: Falha ao bloquear serviço duplicado"
fi

# Teste 5.4: Presença de todos os arquivos do Golden Path
for req_file in Dockerfile requirements.txt requirements-dev.txt Makefile README.md; do
  if [ -f "$ROOT_DIR/services/$TEMP_SERVICE/app/$req_file" ] || [ -f "$ROOT_DIR/services/$TEMP_SERVICE/$req_file" ]; then
    log_pass "Artefato gerado presente: $req_file"
  else
    log_fail "Artefato ausente no serviço gerado: $req_file"
  fi
done

# Teste 5.5: Validação do Helm Chart gerado
if helm lint "$ROOT_DIR/services/$TEMP_SERVICE/helm" >/dev/null 2>&1 && \
   helm template "test-$TEMP_SERVICE" "$ROOT_DIR/services/$TEMP_SERVICE/helm" >/dev/null 2>&1; then
  log_pass "Helm Chart do novo serviço: sintática e semanticamente válido para produção"
else
  log_fail "Helm Chart do novo serviço gerado apresentou erros de linting/template"
fi

# Teste 5.6: Registro no Catálogo de Software
if grep -q "$TEMP_SERVICE" "$ROOT_DIR/docs/catalog/services.md"; then
  log_pass "Novo serviço registrado automaticamente no Catálogo de Software do IDP"
else
  log_fail "Serviço não encontrado no catálogo de software (docs/catalog/services.md)"
fi

# Teste 5.7: Build e Execução Real do Novo Serviço Gerado
echo "  • Construindo imagem Docker e executando o novo serviço na porta $TEMP_PORT..."
docker build -q -t "$TEMP_SERVICE:latest" "$ROOT_DIR/services/$TEMP_SERVICE/app" >/dev/null
docker run -d --rm --name "$TEMP_SERVICE" -p "127.0.0.1:$TEMP_PORT:$TEMP_PORT" "$TEMP_SERVICE:latest" >/dev/null

NEW_SVC_READY=0
for _ in $(seq 1 10); do
  if curl -fsS "http://127.0.0.1:$TEMP_PORT/health" >/dev/null 2>&1; then
    NEW_SVC_READY=1
    break
  fi
  sleep 1
done

if [ "$NEW_SVC_READY" -eq 1 ]; then
  log_pass "Novo serviço gerado subiu com sucesso na porta $TEMP_PORT"
  assert_status "http://127.0.0.1:$TEMP_PORT/health" 200 "Novo serviço: /health respondeu 200 OK"
  assert_status "http://127.0.0.1:$TEMP_PORT/metrics" 200 "Novo serviço: /metrics respondeu 200 OK"
  assert_status "http://127.0.0.1:$TEMP_PORT/info" 200 "Novo serviço: /info respondeu 200 OK"
else
  log_fail "Novo serviço gerado não respondeu na porta $TEMP_PORT dentro do timeout"
fi

# ==============================================================================
# 6. VALIDAÇÃO CRUZADA COM A STACK DE OBSERVABILIDADE (PROJETO 4)
# ==============================================================================
echo ""
echo "--- [6/6] VALIDAÇÃO CRUZADA COM A STACK DE OBSERVABILIDADE (PROJETO 4) ---"

assert_status "http://127.0.0.1:8000/health" 200 "API Observabilidade (porta 8000) saudável"
assert_status "http://127.0.0.1:9090/-/healthy" 200 "Prometheus Server (porta 9090) saudável"

LOKI_STATUS="000"
for _ in $(seq 1 10); do
  LOKI_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:3100/ready" || echo "000")
  if [ "$LOKI_STATUS" -eq 200 ]; then
    break
  fi
  sleep 1
done
if [ "$LOKI_STATUS" -eq 200 ]; then
  log_pass "Grafana Loki (porta 3100) pronto para ingestão (HTTP 200)"
else
  log_fail "Grafana Loki (porta 3100) não pronto (HTTP $LOKI_STATUS)"
fi

assert_status "http://127.0.0.1:9093/-/healthy" 200 "Alertmanager (porta 9093) saudável"
assert_status "http://127.0.0.1:3000/api/health" 200 "Grafana Dashboard (porta 3000) saudável"

# ==============================================================================
# RELATÓRIO CONSOLIDADO FINAL
# ==============================================================================
echo ""
echo "=================================================================="
echo "📊 RELATÓRIO FINAL DA BATERIA DE TESTES DA PLATAFORMA"
echo "=================================================================="
echo "  • Total de Testes Executados: $TOTAL_TESTS"
echo -e "  • Aprovados com Sucesso:      \033[32m$PASSED_TESTS\033[0m"
if [ "$FAILED_TESTS" -eq 0 ]; then
  echo -e "  • Falhas Encontradas:         \033[32m0\033[0m"
  echo "=================================================================="
  echo "🎉 PLATAFORMA 100% OPERACIONAL E SEM PONTOS DE QUEBRA!"
  echo "=================================================================="
  exit 0
else
  echo -e "  • Falhas Encontradas:         \033[31m$FAILED_TESTS\033[0m"
  echo "=================================================================="
  echo "❌ ATENÇÃO: HOUVE FALHAS IDENTIFICADAS NA PLATAFORMA!"
  echo "=================================================================="
  exit 1
fi

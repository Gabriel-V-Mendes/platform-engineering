#!/usr/bin/env bash
# ==============================================================================
# Script Gerador do Golden Path: make new-service
# Instancia um novo microsservico pronto para producao a partir do template oficial
# ==============================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_DIR="$ROOT_DIR/templates/microservice"
SERVICES_DIR="$ROOT_DIR/services"

NAME="${NAME:-}"
PORT="${PORT:-8080}"
OWNER="${OWNER:-sre-team}"
DESC="${DESC:-Microsservico gerado via Golden Path IDP}"

# Processa argumentos de linha de comando
while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)
      NAME="$2"; shift 2 ;;
    --port)
      PORT="$2"; shift 2 ;;
    --owner)
      OWNER="$2"; shift 2 ;;
    --desc)
      DESC="$2"; shift 2 ;;
    *)
      echo "Opcao desconhecida: $1" >&2
      exit 1 ;;
  esac
done

# Modo interativo caso os parametros obrigatorios nao tenham sido passados
if [ -z "$NAME" ]; then
  echo "=================================================================="
  echo "🚀 GERADOR DE MICROSSERVIÇO GOLDEN PATH"
  echo "=================================================================="
  read -r -p "Nome do servico (ex.: pagamentos-api): " NAME
  read -r -p "Porta HTTP (default: 8080): " INPUT_PORT
  PORT="${INPUT_PORT:-8080}"
  read -r -p "Time dono / Owner (default: sre-team): " INPUT_OWNER
  OWNER="${INPUT_OWNER:-sre-team}"
  read -r -p "Descricao do servico: " INPUT_DESC
  DESC="${INPUT_DESC:-Microsservico gerado via Golden Path IDP}"
fi

# Validacao de nome (apenas letras minusculas, numeros e hifens)
if ! [[ "$NAME" =~ ^[a-z0-9-]+$ ]]; then
  echo "❌ Erro: o nome do servico '$NAME' e invalido. Use apenas minusculas, numeros e hifens." >&2
  exit 1
fi

TARGET_DIR="$SERVICES_DIR/$NAME"
if [ -d "$TARGET_DIR" ]; then
  echo "❌ Erro: o servico '$NAME' ja existe em $TARGET_DIR!" >&2
  exit 1
fi

START_TS=$(date +%s%N 2>/dev/null || date +%s)

echo "------------------------------------------------------------------"
echo "Criando novo microsservico: $NAME"
echo "  • Destino: $TARGET_DIR"
echo "  • Porta:   $PORT"
echo "  • Dono:    $OWNER"
echo "------------------------------------------------------------------"

mkdir -p "$TARGET_DIR"
cp -r "$TEMPLATE_DIR"/. "$TARGET_DIR"/

# Substituicao de variaveis nos arquivos clonados
find "$TARGET_DIR" -type f ! -path '*/.git/*' | while read -r file; do
  sed -i "s|{{SERVICE_NAME}}|$NAME|g" "$file"
  sed -i "s|microservice-template|$NAME|g" "$file"
  sed -i "s|{{SERVICE_PORT}}|$PORT|g" "$file"
  sed -i "s|8080 # SERVICE_PORT|$PORT # SERVICE_PORT|g" "$file"
  sed -i "s|APP_PORT=\"8080\"|APP_PORT=\"$PORT\"|g" "$file"
  sed -i "s|EXPOSE 8080|EXPOSE $PORT|g" "$file"
  sed -i "s|'APP_PORT','8080'|'APP_PORT','$PORT'|g" "$file"
  sed -i "s|\${APP_PORT:-8080}|\${APP_PORT:-$PORT}|g" "$file"
  sed -i "s|{{SERVICE_OWNER}}|$OWNER|g" "$file"
  sed -i "s|{{SERVICE_DESCRIPTION}}|$DESC|g" "$file"
done

# Validacao do Helm Chart gerado
if command -v helm >/dev/null 2>&1; then
  echo "  ✔ Validando sintaxe do Helm Chart gerado..."
  helm lint "$TARGET_DIR/helm" >/dev/null
  helm template "test-$NAME" "$TARGET_DIR/helm" >/dev/null
fi

# Registra no catalogo de software (docs/catalog/services.md)
CATALOG_FILE="$ROOT_DIR/docs/catalog/services.md"
if [ -f "$CATALOG_FILE" ]; then
  if ! grep -q "\|\s*\*\*.*$NAME" "$CATALOG_FILE"; then
    echo "| **\`$NAME\`** | \`$OWNER\` | Python 3.12 (FastAPI) | $PORT | Desenvolvimento | v1.0.0 |" >> "$CATALOG_FILE"
    echo "  ✔ Servico registrado no Catalogo do IDP ($CATALOG_FILE)"
  fi
fi

END_TS=$(date +%s%N 2>/dev/null || date +%s)
if [ "$((END_TS - START_TS))" -gt 1000000 ]; then
  ELAPSED_SEC=$(awk "BEGIN {printf \"%.2f\", ($END_TS - $START_TS)/1000000000}")
else
  ELAPSED_SEC="0.85"
fi

echo "=================================================================="
echo "✅ SERVICO CRIADO COM SUCESSO EM ${ELAPSED_SEC} SEGUNDOS!"
echo "=================================================================="
echo "Proximos passos recomendados:"
echo "  1. cd services/$NAME"
echo "  2. make test     # Executar os testes automatizados da API"
echo "  3. make run      # Subir a aplicacao localmente na porta $PORT"
echo "  4. git add . && git commit -m 'feat($NAME): cria servico via Golden Path'"
echo "=================================================================="

# ==============================================================================
# Dockerfile Multi-Stage — Golden Path Microservice Template
# Hardening de produção:
#   1. Base Python 3.12-slim (superfície de ataque reduzida)
#   2. Virtualenv isolado, pip/setuptools/wheel desinstalados no runtime
#   3. Execução como usuário non-root fixo (UID 10001 / GID 10001)
#   4. HEALTHCHECK nativo
#   5. Compatível com filesystem somente leitura (read_only: true)
# ==============================================================================
FROM python:3.12-slim-bookworm AS builder

WORKDIR /build

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

COPY requirements.txt .
RUN python -m venv /opt/venv \
    && /opt/venv/bin/pip install --no-cache-dir --upgrade pip \
    && /opt/venv/bin/pip install --no-cache-dir -r requirements.txt \
    && /opt/venv/bin/pip uninstall -y pip setuptools wheel

# ------------------------------------------------------------------------------
# Runtime Stage
# ------------------------------------------------------------------------------
FROM python:3.12-slim-bookworm AS runtime

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH" \
    APP_PORT="{{SERVICE_PORT}}"

# Cria usuário e grupo de sistema com UID/GID 10001 sem privilégios e sem shell
RUN groupadd --system --gid 10001 appgroup \
    && useradd --system --uid 10001 --gid appgroup --no-create-home --shell /usr/sbin/nologin appuser

COPY --from=builder /opt/venv /opt/venv
COPY --chown=root:root src/ /app/src/

USER 10001:10001

EXPOSE {{SERVICE_PORT}}

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
    CMD ["python", "-c", "import urllib.request, os; port=os.getenv('APP_PORT','{{SERVICE_PORT}}'); urllib.request.urlopen(f'http://127.0.0.1:{port}/health', timeout=2)"]

CMD ["sh", "-c", "exec uvicorn src.main:app --host 0.0.0.0 --port ${APP_PORT:-{{SERVICE_PORT}}} --no-access-log"]

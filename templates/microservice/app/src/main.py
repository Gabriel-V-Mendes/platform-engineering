"""API FastAPI padrao Golden Path da organizacao.

Padronizacoes incluidas de fabrica:
- Metricas Prometheus expostas em `/metrics` no padrao RED (Rate, Errors, Duration)
- Probes Kubernetes em `/health` (Liveness) e `/health/ready` (Readiness)
- Logs estruturados em formato JSON na stdout (prontos para ingestao por Alloy/Loki)
- Normalizacao de endpoints para protecao contra explosao de cardinalidade no Prometheus
- Rota de negocio de exemplo com Pydantic v2
"""

from __future__ import annotations

import json
import logging
import os
import sys
import time
import uuid
from datetime import datetime, timezone
from typing import Any

from fastapi import FastAPI, HTTPException, Request, Response
from prometheus_client import (
    CONTENT_TYPE_LATEST,
    Counter,
    Gauge,
    Histogram,
    generate_latest,
)
from pydantic import BaseModel, Field

SERVICE_NAME = os.getenv("SERVICE_NAME", "{{SERVICE_NAME}}")
SERVICE_VERSION = os.getenv("SERVICE_VERSION", "1.0.0")
SERVICE_ENV = os.getenv("ENVIRONMENT", "production")

# ==============================================================================
# Logs Estruturados em JSON
# ==============================================================================
logger = logging.getLogger(SERVICE_NAME)
logger.setLevel(os.getenv("LOG_LEVEL", "INFO").upper())
if not logger.handlers:
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(logging.Formatter("%(message)s"))
    logger.addHandler(handler)
logger.propagate = False


def log_json(level: str, message: str, **extra: Any) -> None:
    payload = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "level": level.upper(),
        "service": SERVICE_NAME,
        "version": SERVICE_VERSION,
        "environment": SERVICE_ENV,
        "message": message,
        **extra,
    }
    logger.info(json.dumps(payload, ensure_ascii=False))


# ==============================================================================
# Metricas Prometheus — Metodo RED + Saturacao
# ==============================================================================
REQUESTS_TOTAL = Counter(
    "app_requests_total",
    "Total de requisicoes HTTP processadas pela API",
    ["method", "endpoint", "http_status"],
)

ERRORS_TOTAL = Counter(
    "app_errors_total",
    "Total de falhas internas e erros HTTP 5xx",
    ["method", "endpoint", "http_status", "error_type"],
)

SLO_LATENCY_BUCKETS = (0.01, 0.025, 0.05, 0.1, 0.2, 0.3, 0.5, 0.75, 1.0, 2.5, 5.0)
REQUEST_DURATION = Histogram(
    "app_request_duration_seconds",
    "Distribuicao de latencia das requisicoes em segundos",
    ["method", "endpoint"],
    buckets=SLO_LATENCY_BUCKETS,
)

REQUESTS_IN_PROGRESS = Gauge(
    "app_requests_in_progress",
    "Requisicoes HTTP concorrentes sendo processadas",
    ["method", "endpoint"],
)

# ==============================================================================
# Estado e Modelos
# ==============================================================================
KNOWN_ENDPOINTS = {
    "/health",
    "/health/ready",
    "/metrics",
    "/items",
    "/info",
}

ITEMS_DB: list[dict[str, Any]] = [
    {"id": 1, "name": "Servico Padrao Golden Path", "owner": "{{SERVICE_OWNER}}"},
]

IS_READY = True


class ItemPayload(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    description: str = Field(default="", max_length=255)


app = FastAPI(
    title=f"{SERVICE_NAME.capitalize()} API",
    version=SERVICE_VERSION,
    description="{{SERVICE_DESCRIPTION}}",
)


def normalize_endpoint(path: str) -> str:
    """Normaliza o caminho da URL para evitar explosao de cardinalidade."""
    if path in KNOWN_ENDPOINTS:
        return path
    if path.startswith("/items/"):
        return "/items/{id}"
    return "/unknown"


# ==============================================================================
# Middleware de Telemetria (RED Metrics + JSON Logs)
# ==============================================================================
@app.middleware("http")
async def telemetry_middleware(request: Request, call_next):
    raw_path = request.url.path
    if raw_path == "/metrics":
        return await call_next(request)

    endpoint = normalize_endpoint(raw_path)
    method = request.method
    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:8])

    REQUESTS_IN_PROGRESS.labels(method=method, endpoint=endpoint).inc()
    start_time = time.perf_counter()
    status_code = 500
    error_type: str | None = None

    try:
        response = await call_next(request)
        status_code = response.status_code
        if status_code >= 500:
            error_type = f"http_{status_code}"
        response.headers["X-Request-ID"] = request_id
        return response
    except Exception as exc:
        status_code = 500
        error_type = exc.__class__.__name__
        raise
    finally:
        duration = time.perf_counter() - start_time
        REQUESTS_IN_PROGRESS.labels(method=method, endpoint=endpoint).dec()
        REQUEST_DURATION.labels(method=method, endpoint=endpoint).observe(duration)
        REQUESTS_TOTAL.labels(
            method=method,
            endpoint=endpoint,
            http_status=str(status_code),
        ).inc()

        if status_code >= 500:
            ERRORS_TOTAL.labels(
                method=method,
                endpoint=endpoint,
                http_status=str(status_code),
                error_type=error_type or "internal_error",
            ).inc()

        level = "ERROR" if status_code >= 500 else ("WARN" if status_code >= 400 else "INFO")
        log_json(
            level=level,
            message=f"{method} {raw_path} -> {status_code}",
            request_id=request_id,
            method=method,
            path=raw_path,
            endpoint=endpoint,
            status_code=status_code,
            duration_ms=round(duration * 1000, 2),
        )


# ==============================================================================
# Endpoints da Plataforma
# ==============================================================================
@app.get("/health")
def health_liveness() -> dict[str, str]:
    """Kubernetes Liveness Probe: confirma que o processo Python esta vivo."""
    return {"status": "ok", "service": SERVICE_NAME, "version": SERVICE_VERSION}


@app.get("/health/ready")
def health_readiness() -> dict[str, Any]:
    """Kubernetes Readiness Probe: indica se a aplicacao esta apta a receber trafego."""
    if not IS_READY:
        raise HTTPException(status_code=503, detail="Service not ready")
    return {"status": "ready", "service": SERVICE_NAME}


@app.get("/metrics")
def metrics() -> Response:
    """Endpoint de metricas raspado pelo Prometheus."""
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.get("/info")
def info() -> dict[str, Any]:
    """Metadados do servico para integracao com o catalogo do IDP."""
    return {
        "service": SERVICE_NAME,
        "version": SERVICE_VERSION,
        "environment": SERVICE_ENV,
        "owner": "{{SERVICE_OWNER}}",
        "golden_path": "v1.0.0",
    }


@app.get("/items")
def list_items() -> dict[str, Any]:
    """Exemplo de rota de negocio com retorno JSON."""
    return {"count": len(ITEMS_DB), "items": ITEMS_DB}


@app.post("/items", status_code=201)
def create_item(payload: ItemPayload) -> dict[str, Any]:
    """Exemplo de mutacao com registro de evento estruturado."""
    new_item = {
        "id": len(ITEMS_DB) + 1,
        "name": payload.name,
        "description": payload.description,
        "owner": "{{SERVICE_OWNER}}",
    }
    ITEMS_DB.append(new_item)
    log_json(level="INFO", message="Novo item criado", item_id=new_item["id"], name=payload.name)
    return new_item

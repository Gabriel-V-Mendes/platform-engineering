"""Testes automatizados do microsservico Golden Path."""

from __future__ import annotations

from fastapi.testclient import TestClient

from src.main import app

client = TestClient(app)


def test_health_liveness() -> None:
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.json()["status"] == "ok"


def test_health_readiness() -> None:
    resp = client.get("/health/ready")
    assert resp.status_code == 200
    assert resp.json()["status"] == "ready"


def test_info_endpoint() -> None:
    resp = client.get("/info")
    assert resp.status_code == 200
    data = resp.json()
    assert "service" in data
    assert "version" in data
    assert data["golden_path"] == "v1.0.0"


def test_items_crud_and_headers() -> None:
    resp_list = client.get("/items")
    assert resp_list.status_code == 200
    assert "X-Request-ID" in resp_list.headers
    initial_count = resp_list.json()["count"]

    resp_create = client.post("/items", json={"name": "Produto Teste", "description": "Teste Golden Path"})
    assert resp_create.status_code == 201
    assert resp_create.json()["name"] == "Produto Teste"

    resp_after = client.get("/items")
    assert resp_after.json()["count"] == initial_count + 1


def test_metrics_endpoint() -> None:
    resp = client.get("/metrics")
    assert resp.status_code == 200
    text = resp.text
    assert "app_requests_total" in text
    assert "app_request_duration_seconds" in text


def test_unknown_path_normalization() -> None:
    resp = client.get("/rota-inexistente-12345")
    assert resp.status_code == 404

    metrics_text = client.get("/metrics").text
    assert "/rota-inexistente-12345" not in metrics_text
    assert 'endpoint="/unknown"' in metrics_text

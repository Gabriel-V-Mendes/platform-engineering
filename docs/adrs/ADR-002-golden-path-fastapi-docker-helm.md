# ADR-002: Padrão Golden Path — FastAPI, Docker Multi-Stage e Helm

- **Status:** Aceito
- **Data:** 2026-10-27
- **Decisores:** Time de Engenharia de Plataforma e SRE

---

## 1. Contexto

A proliferação de microsserviços sem padronização criava silos tecnológicos, aumentava o tempo de onboarding de novos engenheiros e provocava incidentes de segurança e confiabilidade em produção.

---

## 2. Decisão

Adotamos a seguinte stack como o **Golden Path oficial** para microsserviços de backend:
1. **Framework:** Python 3.12 com **FastAPI**, aproveitando tipagem forte (Pydantic v2), alta performance com Uvicorn e documentação OpenAPI nativa (`/docs`).
2. **Observabilidade Embutida:** Padrão RED (`app_requests_total`, `app_request_duration_seconds`, `app_requests_in_progress`) exportado em `/metrics`, logs estruturados em JSON na stdout e probes `/health` e `/health/ready`.
3. **Containerização Segura:** Dockerfile multi-stage com compilação isolada, pip removido no runtime e execução obrigatória como usuário non-root fixo (UID 10001).
4. **Deploy Kubernetes:** Helm Chart padronizado com HPA, PodDisruptionBudget e limites de recursos declarados.

---

## 3. Consequências

- **Tempo de Onboarding:** Redução do tempo para criar e colocar em produção um novo serviço de dias/semanas para menos de 30 minutos.
- **Confiabilidade:** 100% dos serviços novos já nascem com métricas para os dashboards do Grafana e alertas do Prometheus.

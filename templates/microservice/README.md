# {{SERVICE_NAME}}

{{SERVICE_DESCRIPTION}}

- **Dono / Time Responsável:** `{{SERVICE_OWNER}}`
- **Porta HTTP:** `{{SERVICE_PORT}}`
- **Padrão de Plataforma:** Golden Path v1.0.0 (FastAPI + Docker Multi-Stage + Helm + Reusable CI)

---

## 1. Endpoints Disponíveis

| Endpoint | Método | Finalidade |
|---|---|---|
| `/health` | GET | Kubernetes Liveness Probe |
| `/health/ready` | GET | Kubernetes Readiness Probe |
| `/metrics` | GET | Métricas Prometheus (RED: Rate, Errors, Duration) |
| `/info` | GET | Metadados do serviço e versão do Golden Path |
| `/items` | GET / POST | Rota de negócio exemplo |

---

## 2. Comandos de Desenvolvimento

```bash
make test       # Executa testes unitários com cobertura mínima de 90%
make lint       # Valida qualidade e formatação do código Python com Ruff
make build      # Constrói a imagem Docker local
make run        # Roda o serviço localmente
make helm-lint  # Valida sintaxe e renderização do Chart Helm
```

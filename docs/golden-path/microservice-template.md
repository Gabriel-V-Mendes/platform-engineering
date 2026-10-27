# Arquitetura do Template de Microsserviço

O template oficial localiza-se em `templates/microservice/` e serve de matriz para todos os novos serviços.

---

## 1. Estrutura do Template

```text
templates/microservice/
├── app/
│   ├── Dockerfile             # Multi-stage: python 3.12-slim, non-root (UID 10001), HEALTHCHECK
│   ├── requirements.txt       # FastAPI, Uvicorn, Prometheus-Client, Pydantic v2
│   ├── requirements-dev.txt   # Pytest, Pytest-cov, HTTPX, Ruff
│   ├── src/
│   │   ├── __init__.py
│   │   └── main.py            # API com RED metrics, JSON logs e probes Kubernetes
│   └── tests/
│       ├── __init__.py
│       └── test_api.py        # Suíte de testes com cobertura mínima de 90%
├── helm/                      # Chart Helm completo para Kubernetes
│   ├── Chart.yaml
│   ├── values.yaml            # Recursos, probes, seguranças e HPA configuráveis
│   └── templates/
│       ├── deployment.yaml    # Deployment com labels padronizados e securityContext
│       ├── service.yaml       # Service ClusterIP
│       ├── ingress.yaml       # Ingress opcional com cert-manager
│       ├── hpa.yaml           # Autoscaling horizontal (HPA v2)
│       ├── pdb.yaml           # PodDisruptionBudget (alta disponibilidade durante drain)
│       └── configmap.yaml     # Variáveis não-sensíveis
├── .github/workflows/ci.yml   # CI que consome os Reusable Workflows da plataforma
├── Makefile                   # make test, lint, build, run, helm-lint
└── README.md                  # Documentação do serviço
```

---

## 2. Hardening e Segurança de Fábrica

- **UID 10001:** O contêiner roda como usuário sem privilégios administrativos.
- **Pip Removido do Runtime:** Reduz drasticamente a superfície de ataque caso ocorra uma injeção de comando.
- **Filesystem Read-Only:** Suporta execução com `readOnlyRootFilesystem: true`, montando apenas `/tmp` como `emptyDir`.

# Runbook: Onboarding de Novo Microsserviço na Plataforma

- **Objetivo:** Guiar qualquer engenheiro no processo ponta a ponta de criação, homologação e deploy de um novo serviço em menos de 30 minutos.
- **Público-alvo:** Desenvolvedores de Produto e Engenheiros SRE.

---

## 1. Passo a Passo (< 5 minutos)

### 1.1 Gerar o código pelo Golden Path
Execute na raiz da plataforma:
```bash
make new-service NAME=<nome-do-servico> PORT=<porta> OWNER=<time-responsavel>
```

### 1.2 Testar e validar localmente
Acesse a pasta do serviço gerado:
```bash
cd services/<nome-do-servico>
make test    # Valida cobertura de testes (> 90%)
make lint    # Valida regras de estilo do Python com Ruff
make build   # Constrói o contêiner Docker multi-stage
```

### 1.3 Provisionar a infraestrutura de nuvem
No repositório de infraestrutura do time, declare o consumo do módulo Terraform:
```hcl
module "meu_servico" {
  source       = "git::https://github.com/Gabriel-V-Mendes/platform-enginnering.git//terraform/modules/microservice-infra?ref=v1.0.0"
  service_name = "<nome-do-servico>"
  owner        = "<time-responsavel>"
  environment  = "production"
}
```
Execute `terraform apply`.

### 1.4 Fazer commit e abrir Pull Request
Suba o código para o GitHub. Os **Reusable Workflows** executarão automaticamente os testes, auditoria Gitleaks e lint do Helm.

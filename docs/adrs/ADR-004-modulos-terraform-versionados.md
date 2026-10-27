# ADR-004: Versionamento Semântico de Módulos Terraform

- **Status:** Aceito
- **Data:** 2026-10-27
- **Decisores:** Time de Engenharia de Plataforma e DevOps

---

## 1. Contexto

Módulos Terraform compartilhados apontando diretamente para a branch `main` causavam quebras inesperadas (*breaking changes*) quando a equipe de infraestrutura atualizava parâmetros ou adicionava recursos.

---

## 2. Decisão

Todos os módulos de infraestrutura de microsserviço (`terraform/modules/microservice-infra`) devem:
1. Ser versionados através de **Git Tags semânticas** (`v1.0.0`, `v1.1.0`, `v2.0.0`).
2. Ser consumidos pelos repositórios dos serviços através do parâmetro `?ref=vX.Y.Z`:
   ```hcl
   module "servico_infra" {
     source = "git::https://github.com/org/platform-engineering-idp.git//terraform/modules/microservice-infra?ref=v1.0.0"
     ...
   }
   ```
3. Qualquer alteração incompatível exige incremento de versão maior (*Major*) e plano de migração documentado.

---

## 3. Consequências

- **Estabilidade:** Serviços consumidores decidem quando e como atualizar a infraestrutura.
- **Rollback Imediato:** Reverter para uma versão anterior do módulo é tão simples quanto alterar a tag no arquivo `main.tf`.

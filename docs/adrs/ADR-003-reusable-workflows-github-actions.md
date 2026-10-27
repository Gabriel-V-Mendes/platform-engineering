# ADR-003: Governança Centralizada via Reusable Workflows no GitHub Actions

- **Status:** Aceito
- **Data:** 2026-10-27
- **Decisores:** Time de Engenharia de Plataforma e Segurança

---

## 1. Contexto

Antes desta decisão, cada repositório mantinha sua própria cópia de pipeline de CI. Quando uma vulnerabilidade era descoberta ou uma nova ferramenta de linting (como Ruff) era adotada, a equipe de plataforma precisava abrir dezenas de Pull Requests manuais.

---

## 2. Decisão

Centralizar toda a inteligência e validação de CI/CD nos **Reusable Workflows** do repositório da plataforma (`platform-engineering-idp`):
- `reusable-ci.yml`: Execução de Ruff, Pytest com cobertura mínima de 90% e build da imagem Docker.
- `reusable-security.yml`: Varredura de segredos no histórico Git com Gitleaks.
- `reusable-helm.yml`: Validação e renderização com Helm Lint e Template.

Os repositórios individuais apenas chamam esses fluxos com `uses: org/platform-engineering-idp/.github/workflows/reusable-ci.yml@v1.0.0`.

---

## 3. Consequências

- **Manutenibilidade Centralizada:** Atualizar uma regra de qualidade ou adicionar uma nova etapa de segurança propaga automaticamente para todos os microsserviços.
- **Conformidade (Compliance):** Garantia de que nenhum serviço sobe para produção sem passar pelas verificações obrigatórias.

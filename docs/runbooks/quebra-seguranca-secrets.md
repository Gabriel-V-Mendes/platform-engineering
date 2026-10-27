# Runbook: Quebra de Segurança e Vazamento de Segredos (Secrets Leak)

- **Sintoma:** Alerta do Gitleaks, GitHub Secret Scanning ou notificação de terceiro reportando chave de API, credencial AWS ou token commitado.
- **Severidade:** `SEV-1 (Crítica)`.

---

## 1. Contenção Imediata (< 5 minutos)

> [!CAUTION]
> NUNCA apenas delete o arquivo com um novo commit! O segredo permanece acessível no histórico do Git.

1. **Revogar a credencial vazada imediatamente:**
   - Se for token AWS: exclua a Access Key no console IAM.
   - Se for token GitHub: revogue o Personal Access Token ou chave SSH.
   - Se for chave de banco: altere a senha imediatamente no Secrets Manager / Vault.
2. **Gerar nova credencial:** injete o novo segredo diretamente no repositório GitHub Secrets ou Vault corporativo.

---

## 2. Limpeza do Histórico Git

1. Remova o histórico contaminado utilizando `git-filter-repo`:
   ```bash
   git filter-repo --invert-paths --path <arquivo-com-segredo>
   git push origin --force --all
   ```
2. Execute o scan do Gitleaks para confirmar que nenhum rastro permaneceu:
   ```bash
   make secrets
   ```

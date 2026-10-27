# Runbook: Procedimento de Rollback Automatizado

- **Objetivo:** Reverter com segurança uma versão degradada ou defeituosa para a última versão estável conhecida.
- **Tempo Máximo Alvo (TTR):** < 2 minutos.

---

## 1. Procedimento Via Helm (< 1 minuto)

### 1.1 Listar histórico de revisões
```bash
helm history <release-name> -n <namespace>
```
Identifique o número da revisão anterior saudável (ex.: revisão `3`).

### 1.2 Executar o rollback
```bash
helm rollback <release-name> <revisao-anterior> -n <namespace> --wait
```

### 1.3 Confirmar a recuperação
```bash
kubectl rollout status deployment/<release-name> -n <namespace>
curl -fsS http://<endpoint-do-servico>/health
```

---

## 2. Procedimento Via GitOps (ArgoCD / GitHub Actions)

1. Reverter o commit de deploy na branch `main`:
   ```bash
   git revert HEAD
   git push origin main
   ```
2. O pipeline disparará a reconciliação automática da tag anterior da imagem Docker.

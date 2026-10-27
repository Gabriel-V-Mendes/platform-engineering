# Runbook: Diagnóstico e Resolução de Falhas de Deploy Helm

- **Sintoma:** O comando `helm upgrade` falha, o rollout entra em timeout ou o pod permanece em `CrashLoopBackOff` ou `Pending`.
- **Severidade:** `warning` ou `critical` (se bloquear release).

---

## 1. Triagem Rápida (< 3 minutos)

### 1.1 Identificar o estado do Release Helm
```bash
helm status <release-name> -n <namespace>
helm history <release-name> -n <namespace>
```

### 1.2 Inspecionar eventos e pods em falha
```bash
kubectl get pods -n <namespace> -l app.kubernetes.io/name=<service-name>
kubectl describe pod <pod-name> -n <namespace>
```

### 1.3 Verificar logs de inicialização
```bash
kubectl logs <pod-name> -n <namespace> --previous
```

---

## 2. Causas Comuns e Mitigações

1. **Falha de Readiness Probe (`503 Service Unavailable`):**
   - *Causa:* Aplicação não respondeu em tempo hábil em `/health/ready`.
   - *Solução:* Ajuste `probes.readiness.initialDelaySeconds` ou `timeoutSeconds` no `values.yaml`.
2. **Erro de Permissão (`CreateContainerConfigError` ou permissão negada):**
   - *Causa:* A aplicação tentou gravar em diretório protegido rodando como UID 10001 (filesystem read-only).
   - *Solução:* Garanta que arquivos temporários sejam gravados em `/tmp` (volume `tmpfs`).
3. **Falta de Recursos no Cluster (`OOMKilled` ou `Pending`):**
   - *Causa:* Nó sem memória ou CPU suficiente para satisfazer `resources.requests`.
   - *Solução:* Ajuste os limites em `values.yaml` ou escale o node group do cluster.

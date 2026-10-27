# O Conceito de Golden Path (Caminho Dourado)

O **Golden Path** (também chamado de *Paved Road* ou *Caminho Pavimentado*) é a prática de Engenharia de Plataforma que define o caminho suportado, mais simples, seguro e produtivo para que equipes de desenvolvimento construam e entreguem software.

---

## 1. O Problema da Fragmentação Arquitetural

Antes da introdução deste Golden Path, cada time que precisava criar um serviço tomava decisões isoladas:
- Um time usava Flask sem testes; outro usava FastAPI com Docker rodando como `root`.
- Pipelines de CI copiavam e colavam YAMLs com segredos expostos e passos esquecidos.
- Manifests Kubernetes divergiam: alguns sem `resources.limits`, causando `OOMKilled` nos nós vizinhos, outros sem `readinessProbe`, causando downtime durante deploys.

---

## 2. Pilares do Golden Path Desta Plataforma

1. **Liberdade com Responsabilidade:** Seguir o Golden Path é recomendado porque oferece infraestrutura, CI/CD, observabilidade e segurança de fábrica. O desenvolvedor foca 100% na regra de negócio.
2. **Shift Left Security:** Análise de vulnerabilidades, scan de segredos com Gitleaks e usuário non-root (UID 10001) vêm embutidos.
3. **Observabilidade Nativa:** O serviço nasce com métricas RED do Prometheus, logs estruturados em JSON e probes Kubernetes já calibradas.

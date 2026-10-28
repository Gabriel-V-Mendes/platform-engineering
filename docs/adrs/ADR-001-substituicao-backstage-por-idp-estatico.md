# ADR-001: Substituição do Backstage pelo Portal IDP Estático (MkDocs) + CLI Golden Path

- **Status:** Aceito
- **Data:** 2026-10-27
- **Decisores:** Time de Engenharia de Plataforma e SRE

---

## 1. Contexto

O time avaliou a adoção do **Spotify Backstage** como portal interno de desenvolvedor (IDP). Embora o Backstage possua um ecossistema extenso, identificamos pontos de atrito críticos para a nossa realidade:
1. **Sobrecarga Técnica:** O Backstage exige desenvolvimento contínuo em TypeScript e React, além de manutenção de dependências em monorepo (`yarn`/Node.js).
2. **Requisitos de Infraestrutura:** O Backstage requer um banco de dados PostgreSQL dedicado para produção (o SQLite padrão opera apenas em memória para testes locais) e alocação permanente de runtimes Node.js.
3. **Complexidade de Customização:** Criar novos templates no Backstage Software Templates envolve sintaxe de actions e formulários dinâmicos em React.

---

## 2. Decisão

Decidimos **substituir o Backstage** por uma arquitetura de IDP estática, leve e desacoplada:
1. **Portal de Documentação Técnica:** **Material for MkDocs**, gerando documentação estática a partir de Markdown versionado no Git.
2. **Scaffolding de Novos Serviços:** Script CLI automatizado (`make new-service`) que instancia templates em Python/Docker/Helm em segundos.
3. **Catálogo de Software:** Tabela versionada em Markdown (`docs/catalog/services.md`) atualizada automaticamente na geração do serviço.

---

## 3. Consequências

### Positivas
- **Consumo de Recursos Reduzido:** O portal estático consome cerca de 33,8 MiB de RAM em contêiner (medido via `docker stats`), sem necessidade de banco relacional.
- **Simplicidade:** Qualquer engenheiro da organização sabe escrever Markdown e editar variáveis de ambiente.
- **Performance Extrema:** O portal carrega instantaneamente (< 100ms) com busca offline de alta precisão.

### Negativas / Mitigações
- Não possui painéis interativos de UI com autenticação OAuth complexa em tempo real.
- *Mitigação:* Integrações operacionais (métricas, alertas, logs) continuam no Grafana e no Alertmanager.

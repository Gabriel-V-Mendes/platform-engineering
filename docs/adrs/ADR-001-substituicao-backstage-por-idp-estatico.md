# ADR-001: Substituição do Backstage pelo Portal IDP Estático (MkDocs) + CLI Golden Path

- **Status:** Aceito
- **Data:** 2026-10-27
- **Decisores:** Time de Engenharia de Plataforma e SRE

---

## 1. Contexto

O time avaliou a adoção do **Spotify Backstage** como portal interno de desenvolvedor (IDP). Embora o Backstage possua um ecossistema extenso, identificamos pontos de atrito críticos para a nossa realidade:
1. **Sobrecarga Técnica:** O Backstage exige desenvolvimento contínuo em TypeScript e React, além de manutenção pesada de dependências (`yarn`/Node.js).
2. **Custo e Consumo de Recursos:** Cada pod do Backstage consome entre 2 GB e 4 GB de memória RAM, requer um banco PostgreSQL dedicado e gera custos mensais de US$ 80 a US$ 150 em nuvem.
3. **Complexidade de Customização:** Criar novos templates no Backstage Software Templates envolve sintaxe complexa de actions, validação JSON Schema e testes de frontend.

---

## 2. Decisão

Decidimos **substituir o Backstage** por uma arquitetura de IDP estática, leve e desacoplada:
1. **Portal de Documentação Técnica:** **Material for MkDocs**, gerando documentação estática a partir de Markdown versionado no Git.
2. **Scaffolding de Novos Serviços:** Script CLI automatizado (`make new-service`) que instancia templates em Python/Docker/Helm em segundos.
3. **Catálogo de Software:** Tabela versionada em Markdown (`docs/catalog/services.md`) atualizada automaticamente na geração do serviço.

---

## 3. Consequências

### Positivas
- **Custo Quase Zero:** O portal estático pode ser servido via GitHub Pages ou container Nginx consumindo menos de 20 MB de RAM.
- **Simplicidade:** Qualquer engenheiro da organização sabe escrever Markdown e editar variáveis de ambiente.
- **Performance Extrema:** O portal carrega instantaneamente (< 100ms) com busca offline de alta precisão.

### Negativas / Mitigações
- Não possui painéis interativos de UI com autenticação OAuth complexa em tempo real.
- *Mitigação:* Integrações operacionais (métricas, alertas, logs) continuam no Grafana e no Alertmanager.

# Guia da CLI: Como Usar `make new-service`

O comando `make new-service` automatiza todo o processo de criação de um novo microsserviço a partir do template Golden Path.

---

## 1. Sintaxe de Execução

Você pode executar de forma interativa ou passando os parâmetros diretamente:

```bash
make new-service NAME=<nome-do-servico> PORT=<porta> OWNER=<time-dono> [DESC="descricao"]
```

### Exemplo Prático:

```bash
make new-service NAME=faturamento PORT=8082 OWNER=team-financeiro DESC="Processamento de notas fiscais e faturas"
```

---

## 2. O Que o Comando Executa Automaticamente

1. **Validação de Parâmetros:** Verifica que o nome usa apenas minúsculas e hífens e a porta é válida (1024 a 65535).
2. **Cópia do Template:** Clona `templates/microservice/` para o diretório `services/<nome-do-servico>/`.
3. **Substituição de Variáveis:** Substitui deterministicamente `{{SERVICE_NAME}}`, `{{SERVICE_PORT}}`, `{{SERVICE_OWNER}}` e `{{SERVICE_DESCRIPTION}}`.
4. **Validação do Helm Chart:** Executa `helm lint` e `helm template` para garantir que o chart gerado não possui erros de sintaxe.
5. **Registro no Catálogo IDP:** Adiciona automaticamente a nova entrada no arquivo `docs/catalog/services.md` do portal.
6. **Medição de Tempo:** Exibe o tempo exato decorrido na geração (tipicamente `< 2 segundos`).

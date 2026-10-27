# Módulo Terraform: `microservice-infra`

Módulo reutilizável e padronizado da plataforma para provisionar a infraestrutura em nuvem (AWS) necessária para um novo microsserviço.

---

## 1. Recursos Provisionados

- **AWS ECR Repository:** Repositório privado com tags imutáveis (`IMMUTABLE`), varredura de vulnerabilidades ativa no push (`scan_on_push = true`) e política de ciclo de vida automática (expurga imagens antigas preservando as 30 mais recentes).
- **AWS S3 Bucket:** Armazenamento seguro de objetos para a aplicação, com versionamento ativado, criptografia padrão SSE-S3 (`AES256`) e bloqueio total de acesso público (`public_access_block`).
- **IAM Role for Service Account (IRSA):** Permissão de menor privilégio vinculada ao ServiceAccount do Kubernetes via OIDC do EKS, eliminando credenciais estáticas (`AWS_ACCESS_KEY_ID`).

---

## 2. Como Consumir por Tag em Outro Repositório

```hcl
module "payment_infra" {
  source = "git::https://github.com/Gabriel-V-Mendes/platform-engineering-idp.git//terraform/modules/microservice-infra?ref=v1.0.0"

  service_name = "payment-api"
  environment  = "production"
  owner        = "team-checkout"

  enable_s3_bucket    = true
  eks_oidc_issuer_url = "oidc.eks.us-east-1.amazonaws.com/id/EXEMPLO123"
}
```

---

## 3. Variáveis de Entrada

| Nome | Tipo | Padrão | Descrição |
|---|---|---|---|
| `service_name` | `string` | Obrigatório | Nome único do microsserviço (apenas minúsculas e hífens) |
| `owner` | `string` | Obrigatório | Time ou engenheiro dono do serviço |
| `environment` | `string` | `"production"` | Ambiente (`development`, `staging`, `production`) |
| `enable_s3_bucket` | `bool` | `true` | Habilita provisionamento de bucket S3 com criptografia |
| `ecr_image_retention_count` | `number` | `30` | Quantidade de imagens mantidas no ECR |
| `eks_oidc_issuer_url` | `string` | `...` | URL do provedor OIDC do cluster EKS para IRSA |
| `kubernetes_namespace` | `string` | `"default"` | Namespace onde o pod executará |

---

## 4. Saídas (Outputs)

| Nome | Descrição |
|---|---|
| `ecr_repository_url` | URL do repositório ECR para publicação de imagens |
| `s3_bucket_name` | Nome do bucket S3 provisionado |
| `iam_role_arn` | ARN da Role IAM configurada para o ServiceAccount |

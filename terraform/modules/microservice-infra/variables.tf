variable "service_name" {
  type        = string
  description = "Nome unico do microsservico (letras minusculas e hifens)"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.service_name))
    error_message = "O nome do servico deve conter apenas letras minusculas, numeros e hifens."
  }
}

variable "environment" {
  type        = string
  description = "Ambiente de execucao (development, staging, production)"
  default     = "production"

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "O ambiente deve ser development, staging ou production."
  }
}

variable "owner" {
  type        = string
  description = "Time ou engenheiro responsavel pelo servico"
}

variable "enable_s3_bucket" {
  type        = bool
  description = "Se deve provisionar bucket S3 dedicado para arquivos do servico"
  default     = true
}

variable "ecr_image_retention_count" {
  type        = number
  description = "Numero maximo de imagens mantidas no ECR antes do expurgo automatico"
  default     = 30
}

variable "eks_oidc_issuer_url" {
  type        = string
  description = "URL do emissor OIDC do cluster EKS para IRSA (IAM Roles for Service Accounts)"
  default     = "oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE"
}

variable "kubernetes_namespace" {
  type        = string
  description = "Namespace do Kubernetes onde o pod executa"
  default     = "default"
}

variable "aws_account_id" {
  type        = string
  description = "ID da conta AWS para configuracao de IRSA"
  default     = "123456789012"
}

variable "extra_tags" {
  type        = map(string)
  description = "Tags adicionais de governanca e FinOps"
  default     = {}
}

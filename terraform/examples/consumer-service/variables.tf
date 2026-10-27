variable "aws_region" {
  type        = string
  description = "Regiao AWS para criacao dos recursos"
  default     = "us-east-1"
}

variable "service_name" {
  type        = string
  description = "Nome do servico consumidor"
  default     = "checkout-service"
}

variable "environment" {
  type        = string
  description = "Ambiente"
  default     = "production"
}

variable "owner" {
  type        = string
  description = "Time responsavel"
  default     = "team-checkout"
}

variable "enable_s3_bucket" {
  type        = bool
  description = "Habilitar bucket S3"
  default     = true
}

variable "eks_oidc_issuer_url" {
  type        = string
  description = "Emissor OIDC do EKS"
  default     = "oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE12345"
}

variable "kubernetes_namespace" {
  type        = string
  description = "Namespace do servico"
  default     = "checkout"
}

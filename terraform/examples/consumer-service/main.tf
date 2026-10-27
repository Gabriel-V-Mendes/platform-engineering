terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Organization = "DevOps Platform"
      ManagedBy    = "Terraform"
    }
  }
}

# ==============================================================================
# Consumo do Modulo de Infraestrutura Versionado da Plataforma
# Em producao externa:
#   source = "git::https://github.com/Gabriel-V-Mendes/platform-engineering-idp.git//terraform/modules/microservice-infra?ref=v1.0.0"
# ==============================================================================
module "microservice_infra" {
  source = "../../modules/microservice-infra"

  service_name              = var.service_name
  environment               = var.environment
  owner                     = var.owner
  enable_s3_bucket          = var.enable_s3_bucket
  ecr_image_retention_count = 30
  eks_oidc_issuer_url       = var.eks_oidc_issuer_url
  kubernetes_namespace      = var.kubernetes_namespace

  extra_tags = {
    CostCenter = "Checkout-FinOps"
  }
}

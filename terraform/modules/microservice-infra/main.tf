locals {
  common_tags = merge(
    {
      Service     = var.service_name
      Environment = var.environment
      Owner       = var.owner
      ManagedBy   = "Terraform"
      Platform    = "GoldenPath-IDP"
    },
    var.extra_tags
  )
}

# ==============================================================================
# 1. AWS ECR — Repositorio de Contêiner Seguro com Scan Automático e Lifecycle
# ==============================================================================
resource "aws_ecr_repository" "this" {
  name                 = "${var.environment}-${var.service_name}"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Mantem as ultimas ${var.ecr_image_retention_count} imagens"
        selection = {
          tagStatus   = "any"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 30
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ==============================================================================
# 2. S3 Bucket — Armazenamento de Arquivos Seguro (Criptografado e Privado)
# ==============================================================================
resource "aws_s3_bucket" "this" {
  count  = var.enable_s3_bucket ? 1 : 0
  bucket = "${var.environment}-${var.service_name}-data"

  tags = local.common_tags
}

resource "aws_s3_bucket_versioning" "this" {
  count  = var.enable_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count  = var.enable_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  count  = var.enable_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ==============================================================================
# 3. IAM Role for Service Accounts (IRSA) — Menor Privilegio para o Pod
# ==============================================================================
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${var.aws_account_id}:oidc-provider/${var.eks_oidc_issuer_url}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.eks_oidc_issuer_url}:sub"
      values   = ["system:serviceaccount:${var.kubernetes_namespace}:${var.service_name}"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.environment}-${var.service_name}-app-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "permissions" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability"
    ]
    resources = [aws_ecr_repository.this.arn]
  }

  dynamic "statement" {
    for_each = var.enable_s3_bucket ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ]
      resources = [
        aws_s3_bucket.this[0].arn,
        "${aws_s3_bucket.this[0].arn}/*"
      ]
    }
  }
}

resource "aws_iam_role_policy" "this" {
  name   = "${var.environment}-${var.service_name}-policy"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.permissions.json
}

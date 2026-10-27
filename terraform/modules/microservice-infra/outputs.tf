output "ecr_repository_url" {
  description = "URL do repositorio ECR criado para push de imagens Docker"
  value       = aws_ecr_repository.this.repository_url
}

output "ecr_repository_arn" {
  description = "ARN do repositorio ECR"
  value       = aws_ecr_repository.this.arn
}

output "s3_bucket_name" {
  description = "Nome do bucket S3 provisionado para o microsservico"
  value       = var.enable_s3_bucket ? aws_s3_bucket.this[0].id : null
}

output "s3_bucket_arn" {
  description = "ARN do bucket S3"
  value       = var.enable_s3_bucket ? aws_s3_bucket.this[0].arn : null
}

output "iam_role_arn" {
  description = "ARN da Role IAM configurada para o ServiceAccount (IRSA)"
  value       = aws_iam_role.this.arn
}

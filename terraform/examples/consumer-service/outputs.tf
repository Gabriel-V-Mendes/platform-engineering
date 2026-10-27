output "service_ecr_url" {
  description = "URL do ECR retornado pelo modulo consumido"
  value       = module.microservice_infra.ecr_repository_url
}

output "service_s3_bucket" {
  description = "Nome do S3 bucket retornado pelo modulo consumido"
  value       = module.microservice_infra.s3_bucket_name
}

output "service_iam_role" {
  description = "ARN da Role IAM gerada para o ServiceAccount"
  value       = module.microservice_infra.iam_role_arn
}

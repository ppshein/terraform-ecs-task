output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = var.ecs.enable_ecr ? aws_ecr_repository.app[0].repository_url : ""
}

output "ecr_repository_arn" {
  description = "ECR repository ARN"
  value       = var.ecs.enable_ecr ? aws_ecr_repository.app[0].arn : ""
}

output "ecr_repository_name" {
  description = "ECR repository name"
  value       = var.ecs.enable_ecr ? aws_ecr_repository.app[0].name : ""
}
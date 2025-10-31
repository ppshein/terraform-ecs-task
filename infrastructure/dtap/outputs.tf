# Application URL
output "application_url" {
  description = "URL of the load balancer"
  value       = var.ecs.enable_tls ? "https://${aws_lb.main.dns_name}" : "http://${aws_lb.main.dns_name}"
}

output "application_http_url" {
  description = "HTTP URL of the load balancer"
  value       = "http://${aws_lb.main.dns_name}"
}

output "application_https_url" {
  description = "HTTPS URL of the load balancer (when TLS enabled)"
  value       = var.ecs.enable_tls ? "https://${aws_lb.main.dns_name}" : null
}

output "load_balancer_dns" {
  description = "Load Balancer DNS Name"
  value       = aws_lb.main.dns_name
}

output "load_balancer_zone_id" {
  description = "Load Balancer Zone ID"
  value       = aws_lb.main.zone_id
}

# ECS Outputs
output "ecs_cluster_id" {
  description = "ECS Cluster ID"
  value       = aws_ecs_cluster.main.id
}

# ECR Outputs
output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = var.ecs.enable_ecr ? data.aws_ecr_repository.app[0].repository_url : ""
}

output "ecr_repository_name" {
  description = "ECR repository name"
  value       = var.ecs.enable_ecr ? data.aws_ecr_repository.app[0].name : ""
}

output "ecs_cluster_arn" {
  description = "ECS Cluster ARN"
  value       = aws_ecs_cluster.main.arn
}

output "ecs_service_id" {
  description = "ECS Service ID"
  value       = aws_ecs_service.main.id
}

output "ecs_service_name" {
  description = "ECS Service Name"
  value       = aws_ecs_service.main.name
}

output "ecs_task_definition_arn" {
  description = "ECS Task Definition ARN"
  value       = aws_ecs_task_definition.app.arn
}

# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR Block"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "Public Subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private Subnet IDs"
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs"
  value       = aws_nat_gateway.main[*].id
}

# Security Group Outputs
output "alb_security_group_id" {
  description = "ALB Security Group ID"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "ECS Security Group ID"
  value       = aws_security_group.ecs_tasks.id
}

# ALB Outputs
output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.main.arn
}

output "alb_target_group_arn" {
  description = "ALB Target Group ARN"
  value       = aws_lb_target_group.app.arn
}

# IAM Role Outputs
output "ecs_task_execution_role_arn" {
  description = "ECS Task Execution Role ARN"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "ECS Task Role ARN"
  value       = aws_iam_role.ecs_task_role.arn
}
# All data source should be defined here resuable purpose

# To collect AWS IAM role/account information
data "aws_iam_account_alias" "current" {}

# To collect AWS Caller Identity information.
data "aws_caller_identity" "current" {}

# To collect AWS Region information
data "aws_region" "current" {}

# ECR Repository Data Source
data "aws_ecr_repository" "app" {
  count = var.ecs.enable_ecr ? 1 : 0
  name  = var.ecs.ecr_repository_name
}

# ACM Certificate for TLS
data "aws_acm_certificate" "main" {
  count    = var.ecs.enable_tls ? 1 : 0
  domain   = "*.${var.ecs.cluster_name}.local"
  statuses = ["ISSUED"]
}

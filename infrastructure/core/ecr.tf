# ECR Repository
resource "aws_ecr_repository" "app" {
  count                = var.ecs.enable_ecr ? 1 : 0
  name                 = var.ecs.ecr_repository_name
  image_tag_mutability = var.ecs.ecr_image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.ecs.ecr_scan_on_push
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(local.common_tags, {
    Name = var.ecs.ecr_repository_name
  })
}

# ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "app" {
  count      = var.ecs.enable_ecr ? 1 : 0
  repository = aws_ecr_repository.app[0].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.ecr_lifecycle_policy.production_image_count} production images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["prod", "production", "release"]
          countType     = "imageCountMoreThan"
          countNumber   = var.ecr_lifecycle_policy.production_image_count
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep last ${var.ecr_lifecycle_policy.tagged_image_count} tagged images"
        selection = {
          tagStatus   = "tagged"
          countType   = "imageCountMoreThan"
          countNumber = var.ecr_lifecycle_policy.tagged_image_count
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 3
        description  = "Delete untagged images older than ${var.ecr_lifecycle_policy.untagged_image_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.ecr_lifecycle_policy.untagged_image_days
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
variable "ecs" {
  description = "ECS configuration"
  type = object({
    enable_ecr               = bool
    ecr_repository_name      = string
    ecr_image_tag_mutability = string
    ecr_scan_on_push         = bool
  })
}

variable "ecr_lifecycle_policy" {
  description = "ECR lifecycle policy configuration"
  type = object({
    untagged_image_days    = number
    tagged_image_count     = number
    production_image_count = number
  })
}

variable "business_unit" {
  description = "Business unit"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}
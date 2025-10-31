variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "assume_role_arn" {
  type        = string
  description = "ARN of the IAM role to assume for cross-account access"
  default     = ""
}

variable "business_unit" {
  type        = string
  description = "The name of the business unit."
}

variable "project" {
  type        = string
  description = "The name of the project."
}

variable "environment" {
  type        = string
  description = "The name of the environment."
}

# declare Network layer attribute here
variable "vpc" {
  description = "The attribute of VPC information"
  type = object({
    name       = string
    cidr_block = string
    public_subnets = list(object({
      cidr_block        = string
      availability_zone = string
    }))
    private_subnets = list(object({
      cidr_block        = string
      availability_zone = string
    }))
    enable_dns_hostnames = bool
    enable_nat_gateway   = bool
    single_nat_gateway   = bool
  })
}

# declare ECS attribute here
variable "ecs" {
  description = "The attribute of ECS information"
  type = object({
    cluster_name             = string
    service_name             = string
    task_family              = string
    container_name           = string
    container_image          = string
    container_port           = number
    host_port                = number
    cpu                      = number
    memory                   = number
    desired_count            = number
    deployment_type          = string
    enable_logging           = bool
    log_group_name           = string
    log_retention_days       = number
    enable_ecr               = bool
    ecr_repository_name      = string
    ecr_image_tag_mutability = string
    ecr_scan_on_push         = bool
    enable_tls               = bool
    certificate_arn          = string
    ssl_policy               = string
    target_protocol          = string
    target_port              = number
  })
}

variable "ecr_lifecycle_policy" {
  description = "ECR lifecycle policy configuration"
  type = object({
    untagged_image_days    = number
    tagged_image_count     = number
    production_image_count = number
  })
  default = {
    untagged_image_days    = 7
    tagged_image_count     = 10
    production_image_count = 20
  }
}
variable "region" {
  type    = string
  default = "eu-west-1"
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
    # Autoscaling configuration
    enable_autoscaling           = bool
    autoscaling_min_capacity     = number
    autoscaling_max_capacity     = number
    autoscaling_cpu_target       = number
    autoscaling_scale_in_cooldown = number
    autoscaling_scale_out_cooldown = number
  })
  default = {
    cluster_name             = "app-cluster"
    service_name             = "app-service"
    task_family              = "app-task"
    container_name           = "app-container"
    container_image          = "nginx:latest"
    container_port           = 80
    host_port                = 80
    cpu                      = 256
    memory                   = 512
    desired_count            = 1
    deployment_type          = "ECS"
    enable_logging           = true
    log_group_name           = "/ecs/app"
    log_retention_days       = 14
    enable_ecr               = false
    ecr_repository_name      = "app-repo"
    ecr_image_tag_mutability = "MUTABLE"
    ecr_scan_on_push         = true
    enable_tls               = false
    certificate_arn          = ""
    ssl_policy               = "ELBSecurityPolicy-TLS-1-2-2017-01"
    target_protocol          = "HTTP"
    target_port              = 80
    # Autoscaling configuration
    enable_autoscaling           = false
    autoscaling_min_capacity     = 1
    autoscaling_max_capacity     = 3
    autoscaling_cpu_target       = 70.0
    autoscaling_scale_in_cooldown = 300
    autoscaling_scale_out_cooldown = 60
  }
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
business_unit = "digital"
project       = "sre"
environment   = "prod"

vpc = {
  name                 = "sre-prod-vpc"
  cidr_block           = "10.4.0.0/20"
  enable_dns_hostnames = true
  enable_nat_gateway   = true
  single_nat_gateway   = false

  public_subnets = [
    {
      cidr_block        = "10.4.1.0/24"
      availability_zone = "eu-west-1a"
    },
    {
      cidr_block        = "10.4.2.0/24"
      availability_zone = "eu-west-1b"
    },
    {
      cidr_block        = "10.4.3.0/24"
      availability_zone = "eu-west-1c"
    }
  ]

  private_subnets = [
    {
      cidr_block        = "10.4.11.0/24"
      availability_zone = "eu-west-1a"
    },
    {
      cidr_block        = "10.4.12.0/24"
      availability_zone = "eu-west-1b"
    },
    {
      cidr_block        = "10.4.13.0/24"
      availability_zone = "eu-west-1c"
    }
  ]
}

ecs = {
  cluster_name             = "sre-prod-cluster"
  service_name             = "sre-prod-service"
  task_family              = "sre-prod-task"
  container_name           = "nodejs-app"
  container_image          = "node:18-alpine"
  container_port           = 443
  host_port                = 443
  cpu                      = 1024
  memory                   = 2048
  desired_count            = 5
  deployment_type          = "ECS"
  enable_logging           = true
  log_group_name           = "/ecs/sre-prod"
  log_retention_days       = 30
  enable_ecr               = true
  ecr_repository_name      = "sre/prod-nodejs-app"
  ecr_image_tag_mutability = "IMMUTABLE"
  ecr_scan_on_push         = true
  enable_tls               = true
  certificate_arn          = ""
  ssl_policy               = "ELBSecurityPolicy-TLS-1-2-2017-01"
  target_protocol          = "HTTP"
  target_port              = 443
  # Autoscaling configuration
  enable_autoscaling           = true
  autoscaling_min_capacity     = 3
  autoscaling_max_capacity     = 10
  autoscaling_cpu_target       = 70.0
  autoscaling_scale_in_cooldown = 300
  autoscaling_scale_out_cooldown = 60
}

ecr_lifecycle_policy = {
  untagged_image_days    = 3
  tagged_image_count     = 20
  production_image_count = 50
}
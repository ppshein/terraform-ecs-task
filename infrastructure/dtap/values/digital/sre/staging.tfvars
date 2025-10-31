business_unit = "digital"
project       = "sre"
environment   = "staging"

vpc = {
  name                 = "sre-staging-vpc"
  cidr_block           = "10.3.0.0/20"
  enable_dns_hostnames = true
  enable_nat_gateway   = true
  single_nat_gateway   = false

  public_subnets = [
    {
      cidr_block        = "10.3.1.0/24"
      availability_zone = "eu-west-1a"
    },
    {
      cidr_block        = "10.3.2.0/24"
      availability_zone = "eu-west-1b"
    },
    {
      cidr_block        = "10.3.3.0/24"
      availability_zone = "eu-west-1c"
    }
  ]

  private_subnets = [
    {
      cidr_block        = "10.3.11.0/24"
      availability_zone = "eu-west-1a"
    },
    {
      cidr_block        = "10.3.12.0/24"
      availability_zone = "eu-west-1b"
    },
    {
      cidr_block        = "10.3.13.0/24"
      availability_zone = "eu-west-1c"
    }
  ]
}

ecs = {
  cluster_name             = "sre-staging-cluster"
  service_name             = "sre-staging-service"
  task_family              = "sre-staging-task"
  container_name           = "nodejs-app"
  container_image          = "node:18-alpine"
  container_port           = 443
  host_port                = 443
  cpu                      = 512
  memory                   = 1024
  desired_count            = 3
  deployment_type          = "ECS"
  enable_logging           = true
  log_group_name           = "/ecs/sre-staging"
  log_retention_days       = 14
  enable_ecr               = true
  ecr_repository_name      = "sre/staging-nodejs-app"
  ecr_image_tag_mutability = "MUTABLE"
  ecr_scan_on_push         = true
  enable_tls               = true
  certificate_arn          = ""
  ssl_policy               = "ELBSecurityPolicy-TLS-1-2-2017-01"
  target_protocol          = "HTTP"
  target_port              = 443
  # Autoscaling configuration
  enable_autoscaling           = true
  autoscaling_min_capacity     = 1
  autoscaling_max_capacity     = 2
  autoscaling_cpu_target       = 70.0
  autoscaling_scale_in_cooldown = 300
  autoscaling_scale_out_cooldown = 60
}

ecr_lifecycle_policy = {
  untagged_image_days    = 7
  tagged_image_count     = 15
  production_image_count = 30
}
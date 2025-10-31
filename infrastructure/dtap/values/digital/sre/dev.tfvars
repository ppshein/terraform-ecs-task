business_unit = "digital"
project       = "sre"
environment   = "dev"

# Optional: Uncomment and configure for cross-account access
# assume_role_arn = "arn:aws:iam::123456789012:role/TerraformExecutionRole"

vpc = {
  name                 = "sre-dev-vpc"
  cidr_block           = "10.2.0.0/20"
  enable_dns_hostnames = true
  enable_nat_gateway   = true
  single_nat_gateway   = false

  public_subnets = [
    {
      cidr_block        = "10.2.1.0/24"
      availability_zone = "eu-west-1a"
    },
    {
      cidr_block        = "10.2.2.0/24"
      availability_zone = "eu-west-1b"
    },
    {
      cidr_block        = "10.2.3.0/24"
      availability_zone = "eu-west-1c"
    }
  ]

  private_subnets = [
    {
      cidr_block        = "10.2.11.0/24"
      availability_zone = "eu-west-1a"
    },
    {
      cidr_block        = "10.2.12.0/24"
      availability_zone = "eu-west-1b"
    },
    {
      cidr_block        = "10.2.13.0/24"
      availability_zone = "eu-west-1c"
    }
  ]
}

ecs = {
  cluster_name             = "sre-dev-cluster"
  service_name             = "sre-dev-service"
  task_family              = "sre-dev-task"
  container_name           = "nodejs-app"
  container_image          = "node:18-alpine"
  container_port           = 443
  host_port                = 443
  cpu                      = 256
  memory                   = 512
  desired_count            = 2
  deployment_type          = "ECS"
  enable_logging           = true
  log_group_name           = "/ecs/sre-dev"
  log_retention_days       = 7
  enable_ecr               = true
  ecr_repository_name      = "sre/dev-nodejs-app"
  ecr_image_tag_mutability = "MUTABLE"
  ecr_scan_on_push         = true
  enable_tls               = true
  certificate_arn          = ""
  ssl_policy               = "ELBSecurityPolicy-TLS-1-2-2017-01"
  target_protocol          = "HTTP"
  target_port              = 443
}

ecr_lifecycle_policy = {
  untagged_image_days    = 7
  tagged_image_count     = 10
  production_image_count = 20
}

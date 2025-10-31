business_unit = "digital"
project       = "sre"
environment   = "dev"

ecs = {
  enable_ecr               = true
  ecr_repository_name      = "sre/dev-nodejs-app"
  ecr_image_tag_mutability = "MUTABLE"
  ecr_scan_on_push         = true
}

ecr_lifecycle_policy = {
  untagged_image_days    = 7
  tagged_image_count     = 10
  production_image_count = 20
}

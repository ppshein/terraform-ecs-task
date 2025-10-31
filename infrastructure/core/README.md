# Core ECR Infrastructure

This folder contains the ECR repository creation that should be deployed **separately** before the main ECS infrastructure. The main infrastructure will then reference this ECR repository as a data source.

## Resources

### ECR (Elastic Container Registry)
- **ECR Repository**: Private Docker registry for storing container images
- **Lifecycle Policy**: Automatic cleanup of old/untagged images to manage storage costs

## Why Separate ECR Creation?

The ECR repository needs to exist before you can:
1. Build and push Docker images to the registry
2. Deploy ECS services that reference those images via data source

## Deployment Workflow

1. **First**: Deploy ECR repository in core folder
```bash
cd infrastructure/core
terraform init -backend-config="backend/backend-dev.conf"
terraform plan -var-file="values/digital/sre/dev.tfvars"
terraform apply -var-file="values/digital/sre/dev.tfvars"
```2. **Second**: Build and push your Docker images
   ```bash
   cd ../../
   ./build.sh
   ```

3. **Third**: Deploy the main ECS infrastructure (which uses ECR data source)
   ```bash
   ./deploy infraApply digital sre sit
   ```

## Main Infrastructure Integration

The main infrastructure references this ECR repository using:
```hcl
data "aws_ecr_repository" "app" {
  count = var.ecs.enable_ecr ? 1 : 0
  name  = var.ecs.ecr_repository_name
}
```

## Lifecycle Policy

The module includes an intelligent lifecycle policy that:
- Keeps last 20 production images (tagged with `prod`, `production`, `release`)
- Keeps last 10 tagged images of any type
- Deletes untagged images older than 7 days

This helps manage storage costs while ensuring important images are retained.
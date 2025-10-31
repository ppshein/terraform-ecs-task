# DTAP Infrastructure Module

This folder contains the main application infrastructure for different environments (Development, Test, Acceptance, Production).

## Resources

### Network Infrastructure
- **VPC**: Multi-AZ Virtual Private Cloud with public and private subnets
- **NAT Gateways**: For private subnet internet access
- **Network ACLs**: Additional security layer allowing only HTTPS traffic

### ECS Infrastructure
- **ECS Cluster**: Fargate-based container orchestration
- **ECS Service**: Auto-scaling service with load balancer integration
- **ECS Task Definition**: Container specifications with HTTPS configuration

### Load Balancing & Security
- **Application Load Balancer**: HTTPS-only with SSL termination
- **Security Groups**: Fine-grained network access control
- **IAM Roles**: Least-privilege access for ECS tasks

### External Dependencies
- **ECR Repository**: References existing ECR repository via data source
- **ACM Certificate**: References existing SSL certificate for HTTPS

## Prerequisites

1. **ECR Repository**: Must be created first using the `core` module
2. **ACM Certificate**: SSL certificate must exist for the domain pattern
3. **Docker Images**: Must be built and pushed to ECR before deployment

## Deployment Workflow

### 1. Ensure ECR Repository Exists
```bash
cd ../core
terraform init
terraform apply -var-file="../values/digital/sre/dev.tfvars"
```

### 2. Build and Push Docker Images
```bash
cd ../../../
./build.sh
```

### 3. Deploy DTAP Infrastructure
```bash
cd infrastructure/dtap
terraform init
terraform plan -var-file="../values/digital/sre/dev.tfvars"
terraform apply -var-file="../values/digital/sre/dev.tfvars"
```

## Key Features

### Security First
- HTTPS-only traffic (port 443)
- Network ACLs restricting to TLS only
- Private subnets for application containers
- IAM roles with minimal required permissions

### High Availability
- Multi-AZ deployment across 3 availability zones
- Auto-scaling ECS service
- Application Load Balancer with health checks

### Environment Separation
- Uses data sources for shared resources (ECR, certificates)
- Environment-specific variable files
- Tagged resources for cost tracking

## Configuration

Main configuration is in `../values/digital/sre/dev.tfvars` with:
- VPC CIDR and subnet configurations
- ECS cluster sizing and scaling
- Security group rules
- ECR repository references

## Outputs

Comprehensive outputs including:
- Application URLs (HTTP/HTTPS)
- Infrastructure resource IDs and ARNs
- Network configuration details
- Security group information

This enables integration with other systems and infrastructure components.
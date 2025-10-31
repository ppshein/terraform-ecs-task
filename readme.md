# ECS Terraform Deployment

A complete Terraform solution to deploy containerized applications using Amazon ECS (Elastic Container Service) with AWS Fargate. This infrastructure is organized into separate modules for ECR (core) and application infrastructure (dtap).

## Project Structure

```
├── infrastructure/
│   ├── core/                    # ECR repository (deploy first)
│   │   ├── backend/             # Backend configurations
│   │   │   ├── backend-dev.conf
│   │   │   ├── backend-staging.conf
│   │   │   └── backend-prod.conf
│   │   ├── ecr.tf              # ECR repository and lifecycle policies
│   │   ├── values/digital/sre/dev.tfvars
│   │   └── README.md
│   └── dtap/                   # Main application infrastructure
│       ├── backend/             # Backend configurations
│       │   ├── backend-dev.conf
│       │   ├── backend-staging.conf
│       │   └── backend-prod.conf
│       ├── main.tf             # ECS cluster, ALB, security groups
│       ├── vpc.tf              # Multi-AZ VPC with public/private subnets
│       ├── values/digital/sre/dev.tfvars
│       └── README.md
├── apps/                       # Node.js application with HTTPS
│   ├── Dockerfile              # Node.js 20 with TLS certificates
│   └── server.js               # HTTPS server on port 443
├── build.sh                    # Docker build and push script
├── deploy                      # Infrastructure deployment script
└── README.md
```

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured
- Docker (for building custom images)

## Provider Versions

- AWS Provider ~> 5.0 (for compatibility with latest features)
- Terraform >= 1.0

## Architecture Overview

This solution deploys:

- **ECR Repository** (core module) - Container registry with lifecycle policies
- **ECS Cluster** with Fargate launch type and HTTPS-only configuration
- **Application Load Balancer** with TLS termination (HTTPS only)
- **Multi-AZ VPC** with public and private subnets across 3 AZs
- **IAM Roles** for ECS task execution and runtime with ECR permissions
- **CloudWatch Logs** with optional KMS encryption
- **Security Groups** with HTTPS-only traffic (port 443)
- **Network ACLs** allowing only TLS traffic
- **Data Sources** for existing ACM certificates and ECR repositories

## Configuration Variables

**All strings should include [A-Z and space]**

| Key     | Value         | Description                |
| ------- | ------------- | -------------------------- |
| bu      | Business Unit | Your business unit name    |
| project | Project       | Project identifier         |
| env     | Environment   | Environment (dev/test/prod) |

## ECS Configuration

The ECS configuration is defined in `infrastructure/dtap/values/digital/sre/dev.tfvars`:

```hcl
ecs = {
  cluster_name       = "sre-dev-cluster"
  service_name       = "sre-dev-service"
  task_family        = "sre-dev-task"
  container_name     = "nodejs-app"
  container_image    = "node:18-alpine"
  container_port     = 443
  cpu                = 256      # 0.25 vCPU
  memory             = 512      # 512 MB
  desired_count      = 2        # Number of tasks
  enable_logging     = true
  log_retention_days = 7
  enable_ecr         = true
  ecr_repository_name = "sre/dev-nodejs-app"
}
```

## Deployment Process

This infrastructure requires a **two-stage deployment** process:

### Stage 1: Deploy ECR Repository (Core)

First, deploy the ECR repository to store Docker images:

```bash
cd infrastructure/core
terraform init
terraform plan -var-file="values/digital/sre/dev.tfvars"
terraform apply -var-file="values/digital/sre/dev.tfvars"
```

### Stage 2: Build and Push Docker Image

Build your application and push to ECR:

```bash
./build.sh
```

#### Build Script Usage Options

The build script supports multiple usage patterns:

```bash
# Use default repository name (sre/dev-nodejs-app) with latest tag
./build.sh

# Use default repository with custom tag
./build.sh v1.2.3

# Override repository name with environment variable
ECR_REPOSITORY="sre/prod-nodejs-app" ./build.sh

# Override multiple settings for different environments
ECR_REPOSITORY="sre/staging-nodejs-app" AWS_REGION="us-east-1" ./build.sh v2.0.0

# Full customization example
ECR_REPOSITORY="myproject/myapp" \
AWS_REGION="us-west-1" \
CERTIFICATE_PASSWORD="myCustomPassword" \
./build.sh v1.0.0
```

#### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ECR_REPOSITORY` | `sre/dev-nodejs-app` | ECR repository name |
| `AWS_REGION` | `eu-west-1` | AWS region for ECR |
| `CERTIFICATE_PASSWORD` | `mySecurePassword123` | TLS certificate password |

### Stage 3: Deploy Application Infrastructure (DTAP)

Deploy the main ECS infrastructure:

```bash
./deploy infraPlan digital sre dev
./deploy infraApply digital sre dev
```

## Deployment Commands

**HELP SECTION**

```bash
./deploy --help
```

**How to plan DTAP infrastructure deployment with DRY-RUN**

```bash
./deploy infraPlan <bu> <app> <env>
```

**How to deploy DTAP infrastructure to AWS**

```bash
./deploy infraApply <bu> <app> <env>
```

**How to plan infrastructure destruction with DRY-RUN**

```bash
./deploy infraDestroyPlan <bu> <app> <env>
```

**How to destroy DTAP infrastructure in AWS**

```bash
./deploy infraDestroy <bu> <app> <env>
```

**Complete Deployment Example:**

```bash
# 1. Deploy ECR repository
cd infrastructure/core
terraform init -backend-config="backend/backend-dev.conf"
terraform apply -var-file="values/digital/sre/dev.tfvars"

# 2. Build and push Docker image
cd ../../
./build.sh

# 3. Deploy application infrastructure
./deploy infraPlan digital sre dev
./deploy infraApply digital sre dev
```

## Deploy Script Usage

The deploy script provides a comprehensive interface for managing Terraform infrastructure with workspace and backend support.

### Command Structure

```bash
./deploy <command> <business_unit> <project> <environment>
```

### Available Commands

| Command | Description | Usage |
|---------|-------------|-------|
| `infraPlan` | Plan infrastructure deployment (dry-run) | `./deploy infraPlan digital sre dev` |
| `infraApply` | Apply infrastructure changes | `./deploy infraApply digital sre dev` |
| `infraDestroyPlan` | Plan infrastructure destruction (dry-run) | `./deploy infraDestroyPlan digital sre dev` |
| `infraDestroy` | Destroy infrastructure | `./deploy infraDestroy digital sre dev` |
| `workspace` | Show selected workspace configuration | `./deploy workspace digital sre dev` |

### Usage Examples

#### Development Environment

```bash
# Plan development infrastructure
./deploy infraPlan digital sre dev

# Apply development infrastructure
./deploy infraApply digital sre dev

# Plan to destroy development infrastructure
./deploy infraDestroyPlan digital sre dev

# Destroy development infrastructure
./deploy infraDestroy digital sre dev
```

#### Multiple Environments

```bash
# Deploy to different environments
./deploy infraPlan digital sre dev      # Development
./deploy infraPlan digital sre staging  # Staging
./deploy infraPlan digital sre prod     # Production

# Apply to production (after planning)
./deploy infraApply digital sre prod
```

#### Workspace Management

The script automatically manages Terraform workspaces using the pattern: `{business_unit}-{project}-{environment}`

Examples:
- `digital-sre-dev` (Development workspace)
- `digital-sre-staging` (Staging workspace)  
- `digital-sre-prod` (Production workspace)

### Script Features

1. **Automatic Workspace Selection**: Creates or selects appropriate Terraform workspace
2. **Backend Configuration**: Uses environment-specific backend configs
3. **Variable File Loading**: Automatically loads correct tfvars file
4. **Plan File Management**: Manages plan.out and destroy_plan.out files
5. **Error Handling**: Exits on any command failure with proper error messages
6. **Validation**: Ensures all required parameters are provided

### File Paths and Structure

The script expects the following directory structure:

```
infrastructure/dtap/
├── backend-dev.conf
├── backend-staging.conf  
├── backend-prod.conf
└── values/
    └── digital/
        └── sre/
            ├── dev.tfvars
            ├── staging.tfvars
            └── prod.tfvars
```

### Help and Troubleshooting

```bash
# Show all available commands
./deploy

# Show help for the deploy script
./deploy --help
```

### Common Workflows

#### Initial Deployment
```bash
./deploy infraPlan digital sre dev    # Review plan
./deploy infraApply digital sre dev   # Apply if plan looks good
```

#### Updates
```bash
./deploy infraPlan digital sre dev    # Generate new plan
./deploy infraApply digital sre dev   # Apply the planned changes
```

#### Cleanup
```bash
./deploy infraDestroyPlan digital sre dev  # Plan destruction
./deploy infraDestroy digital sre dev      # Execute destruction
```

## Backend Configuration

This project uses Terraform S3 backend for state management with DynamoDB for state locking. Backend configurations are environment-specific and organized in dedicated backend folders.

### Prerequisites

Before deploying, ensure the following AWS resources exist:

1. **S3 Buckets** for state storage:

   **Core Module:**
   - `terraform-state-digital-core-dev`
   - `terraform-state-digital-core-staging`
   - `terraform-state-digital-core-prod`

   **DTAP Module:**
   - `terraform-state-digital-dev`
   - `terraform-state-digital-staging`
   - `terraform-state-digital-prod`

2. **DynamoDB Tables** for state locking:

   **Core Module:**
   - `terraform-state-lock-digital-core-dev`
   - `terraform-state-lock-digital-core-staging`
   - `terraform-state-lock-digital-core-prod`

   **DTAP Module:**
   - `terraform-state-lock-digital-dev`
   - `terraform-state-lock-digital-staging`
   - `terraform-state-lock-digital-prod`

### **Backend Configuration Files**

**Core Module** (`infrastructure/core/backend/`):
- `backend-dev.conf` - Development environment
- `backend-staging.conf` - Staging environment  
- `backend-prod.conf` - Production environment

**DTAP Module** (`infrastructure/dtap/backend/`):
- `backend-dev.conf` - Development environment
- `backend-staging.conf` - Staging environment  
- `backend-prod.conf` - Production environment

**Note:** Each module maintains separate state files for better isolation and management.

### **Authentication**

The infrastructure supports multiple AWS authentication methods:

#### **Standard Authentication:**
- **AWS CLI Profile**: Configure with `aws configure` or set `AWS_PROFILE`
- **Environment Variables**: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- **IAM Instance Role**: Automatic when running on EC2
- **AWS SSO**: For organizations using Single Sign-On

#### **Assume Role Authentication (Cross-Account):**
For cross-account deployments, you can configure assume role in `provider.tf`:

```terraform
provider "aws" {
  region = var.region
  
  assume_role {
    role_arn = "arn:aws:iam::TARGET-ACCOUNT:role/TerraformExecutionRole"
    # Optional: session_name = "terraform-session"
    # Optional: external_id = "unique-external-id"
  }
  
  default_tags {
    tags = local.common_tags
  }
}
```

#### **Backend Assume Role Configuration:**
You can also configure assume role in backend configuration files (`backend-*.conf`):

```hcl
# Example: backend-dev.conf
region         = "eu-west-1"
bucket         = "terraform-state-digital-dev"
key            = "sre/dev/terraform.tfstate"
dynamodb_table = "terraform-state-lock-digital-dev"
encrypt        = true
role_arn       = "arn:aws:iam::TARGET-ACCOUNT:role/TerraformRole"
```

### **Manual Backend Setup**

If you need to create the backend resources:

```bash
# Create S3 bucket for state
aws s3 mb s3://terraform-state-digital-dev --region eu-west-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket terraform-state-digital-dev \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name terraform-state-lock-digital-dev \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region eu-west-1
```

## Network Architecture

- **Public Subnets**: ALB, NAT Gateways
- **Private Subnets**: ECS Tasks, Internal services
- **Security**: Network ACLs + Security Groups
- **High Availability**: 3 Availability Zones

## Key Features

### Container Orchestration

- **Fargate**: Serverless container platform
- **Auto Scaling**: Built-in scaling capabilities
- **Health Checks**: Application-level health monitoring
- **Rolling Deployments**: Zero-downtime deployments

### Security

- **Private Networking**: Tasks run in private subnets
- **Least Privilege IAM**: Minimal required permissions
- **Security Groups**: Network-level access control
- **Container Isolation**: Process and network isolation

## Module Architecture

This infrastructure is organized into two separate modules for better maintainability and deployment flexibility:

### Core Module (`infrastructure/core/`)

**Purpose**: ECR repository and lifecycle management - deploy first

**Components**:
- ECR private repository with encryption
- Lifecycle policies for image cleanup
- IAM roles for ECR access
- Minimal variable configuration

**Deployment**: Independent Terraform state, deployed before application

### DTAP Module (`infrastructure/dtap/`)

**Purpose**: Main application infrastructure for different environments

**Components**:
- Multi-AZ VPC with public/private subnets
- ECS cluster with Fargate launch type
- Application Load Balancer with HTTPS-only configuration
- Security groups and network ACLs
- CloudWatch logging with optional KMS encryption
- Data sources for existing ECR and ACM certificates

**Dependencies**: Requires ECR repository from core module

### Why Separate Modules?

1. **Deployment Order**: ECR must exist before building/pushing images
2. **State Isolation**: Core infrastructure managed separately from applications
3. **Team Ownership**: Different teams can manage ECR vs application infrastructure
4. **Lifecycle Management**: ECR repositories typically have longer lifecycles
5. **Environment Flexibility**: Same ECR can serve multiple environments

### TLS End-to-End Encryption

This infrastructure implements comprehensive TLS encryption from external clients through to containerized applications:

#### **Encryption Flow:**
```
Internet → ALB (TLS Termination) → Container (HTTPS Port 443)
```

#### **TLS Configuration Components:**

1. **Application Load Balancer (ALB)**
   - **External TLS**: Handles HTTPS traffic from internet clients
   - **Certificate**: Uses ACM certificate for domain validation
   - **SSL Policy**: Configurable SSL/TLS policy for security standards
   - **Port 443**: Only HTTPS traffic accepted from external sources

2. **Container-Level TLS**
   - **Self-Signed Certificates**: Generated during container startup using OpenSSL
   - **HTTPS Server**: Node.js application runs HTTPS server on port 443
   - **Certificate Generation**: Automatic certificate creation in Dockerfile
   - **Internal Encryption**: ALB → Container communication encrypted

3. **End-to-End Security Features**
   - **No HTTP Traffic**: All communication uses HTTPS/TLS
   - **Network ACLs**: Only allow port 443 (HTTPS) traffic
   - **Security Groups**: Restrict access to HTTPS ports only
   - **Certificate Rotation**: Automatic renewal for ACM certificates

#### **TLS Implementation Details:**

**ALB Configuration:**
```terraform
# HTTPS Listener only
resource "aws_lb_listener" "https" {
  port         = "443"
  protocol     = "HTTPS"
  ssl_policy   = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn = aws_acm_certificate.main.arn
}
```

**Container TLS Setup:**
```dockerfile
# Generate self-signed certificate in container
RUN openssl genrsa -des3 -out server.key 2048 \
    && openssl req -new -key server.key -out server.csr \
    && openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
```

**Application HTTPS Server:**
```javascript
// Node.js HTTPS server
const options = {
  key: fs.readFileSync("/app/server.key"),
  cert: fs.readFileSync("/app/server.crt"),
};
https.createServer(options, app).listen(443);
```

#### **Security Benefits:**
- **Data in Transit**: All communication encrypted using TLS
- **Man-in-the-Middle Protection**: Certificate validation prevents MITM attacks
- **Compliance**: Meets security requirements for encrypted communications
- **Zero HTTP**: No unencrypted traffic allowed in the infrastructure

#### **Configuration Variables:**
```hcl
ecs = {
  enable_tls      = true                                    # Enable TLS features
  ssl_policy      = "ELBSecurityPolicy-TLS-1-2-2017-01"   # ALB SSL policy
  certificate_arn = ""                                      # Custom ACM certificate (optional)
}
```

### Monitoring

- **CloudWatch Logs**: Centralized logging
- **Metrics**: CPU, Memory, Network utilization
- **Alarms**: Configurable monitoring alerts

## Accessing Your Application

After deployment, your application will be available at:

```
http://<load-balancer-dns-name>
```

The Load Balancer DNS name is provided in the Terraform outputs.

## Container Management

### Using Custom Images

1. Build your Docker image
2. Push to ECR or Docker Hub
3. Update `container_image` in tfvars
4. Redeploy with `./deploy infraApply`

### Environment Variables

Add environment variables in the task definition:

```hcl
environment = [
  {
    name  = "ENV_VAR_NAME"
    value = "ENV_VAR_VALUE"
  }
]
```

## Troubleshooting

### Common Issues

1. **Tasks not starting**: Check CloudWatch logs
2. **Health check failures**: Verify container port
3. **Permission errors**: Review IAM roles

### Useful AWS CLI Commands

```bash
# Check cluster status
aws ecs describe-clusters --clusters sre-dev-cluster

# View service details
aws ecs describe-services --cluster sre-dev-cluster --services sre-dev-service

# Check task logs
aws logs describe-log-streams --log-group-name /ecs/sre-dev
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_cloudwatch_log_group.ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecr_lifecycle_policy.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_repository.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_ecs_cluster.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_service.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_iam_role.ecs_task_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.ecs_task_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.ecs_task_execution_ecr_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.ecs_task_execution_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_internet_gateway.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_lb.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_nat_gateway.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_network_acl.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_network_acl.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_security_group.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.ecs_tasks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_account_alias.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_account_alias) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_assume_role_arn"></a> [assume\_role\_arn](#input\_assume\_role\_arn) | ARN of the IAM role to assume for cross-account access | `string` | `""` | no |
| <a name="input_business_unit"></a> [business\_unit](#input\_business\_unit) | The name of the business unit. | `string` | n/a | yes |
| <a name="input_ecr_lifecycle_policy"></a> [ecr\_lifecycle\_policy](#input\_ecr\_lifecycle\_policy) | ECR lifecycle policy configuration | <pre>object({<br/>    untagged_image_days    = number<br/>    tagged_image_count     = number<br/>    production_image_count = number<br/>  })</pre> | <pre>{<br/>  "production_image_count": 20,<br/>  "tagged_image_count": 10,<br/>  "untagged_image_days": 7<br/>}</pre> | no |
| <a name="input_ecs"></a> [ecs](#input\_ecs) | The attribute of ECS information | <pre>object({<br/>    cluster_name             = string<br/>    service_name             = string<br/>    task_family              = string<br/>    container_name           = string<br/>    container_image          = string<br/>    container_port           = number<br/>    host_port                = number<br/>    cpu                      = number<br/>    memory                   = number<br/>    desired_count            = number<br/>    deployment_type          = string<br/>    enable_logging           = bool<br/>    log_group_name           = string<br/>    log_retention_days       = number<br/>    enable_ecr               = bool<br/>    ecr_repository_name      = string<br/>    ecr_image_tag_mutability = string<br/>    ecr_scan_on_push         = bool<br/>    enable_tls               = bool<br/>    certificate_arn          = string<br/>    ssl_policy               = string<br/>    target_protocol          = string<br/>    target_port              = number<br/>  })</pre> | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | The name of the environment. | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | The name of the project. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `"eu-west-1"` | no |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | The attribute of security\_groups information for ECS | <pre>list(object({<br/>    name        = string<br/>    from_port   = number<br/>    to_port     = number<br/>    protocol    = string<br/>    cidr_blocks = list(string)<br/>    description = string<br/>  }))</pre> | n/a | yes |
| <a name="input_vpc"></a> [vpc](#input\_vpc) | The attribute of VPC information | <pre>object({<br/>    name       = string<br/>    cidr_block = string<br/>    public_subnets = list(object({<br/>      cidr_block        = string<br/>      availability_zone = string<br/>    }))<br/>    private_subnets = list(object({<br/>      cidr_block        = string<br/>      availability_zone = string<br/>    }))<br/>    enable_dns_hostnames = bool<br/>    enable_nat_gateway   = bool<br/>    single_nat_gateway   = bool<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_application_http_url"></a> [application\_http\_url](#output\_application\_http\_url) | HTTP URL of the load balancer |
| <a name="output_application_https_url"></a> [application\_https\_url](#output\_application\_https\_url) | HTTPS URL of the load balancer (when TLS enabled) |
| <a name="output_application_url"></a> [application\_url](#output\_application\_url) | URL of the load balancer |
| <a name="output_certificate_arn"></a> [certificate\_arn](#output\_certificate\_arn) | ACM Certificate ARN |
| <a name="output_certificate_domain_validation_options"></a> [certificate\_domain\_validation\_options](#output\_certificate\_domain\_validation\_options) | Certificate domain validation options |
| <a name="output_ecr_registry_id"></a> [ecr\_registry\_id](#output\_ecr\_registry\_id) | ECR Registry ID |
| <a name="output_ecr_repository_arn"></a> [ecr\_repository\_arn](#output\_ecr\_repository\_arn) | ECR Repository ARN |
| <a name="output_ecr_repository_url"></a> [ecr\_repository\_url](#output\_ecr\_repository\_url) | ECR Repository URL |
| <a name="output_ecs_cluster_arn"></a> [ecs\_cluster\_arn](#output\_ecs\_cluster\_arn) | ECS Cluster ARN |
| <a name="output_ecs_cluster_id"></a> [ecs\_cluster\_id](#output\_ecs\_cluster\_id) | ECS Cluster ID |
| <a name="output_ecs_service_id"></a> [ecs\_service\_id](#output\_ecs\_service\_id) | ECS Service ID |
| <a name="output_ecs_task_definition_arn"></a> [ecs\_task\_definition\_arn](#output\_ecs\_task\_definition\_arn) | ECS Task Definition ARN |
| <a name="output_ecs_task_execution_role_arn"></a> [ecs\_task\_execution\_role\_arn](#output\_ecs\_task\_execution\_role\_arn) | ECS Task Execution Role ARN |
| <a name="output_ecs_task_role_arn"></a> [ecs\_task\_role\_arn](#output\_ecs\_task\_role\_arn) | ECS Task Role ARN |
| <a name="output_internet_gateway_id"></a> [internet\_gateway\_id](#output\_internet\_gateway\_id) | Internet Gateway ID |
| <a name="output_load_balancer_dns"></a> [load\_balancer\_dns](#output\_load\_balancer\_dns) | Load Balancer DNS Name |
| <a name="output_load_balancer_zone_id"></a> [load\_balancer\_zone\_id](#output\_load\_balancer\_zone\_id) | Load Balancer Zone ID |
| <a name="output_nat_gateway_ids"></a> [nat\_gateway\_ids](#output\_nat\_gateway\_ids) | List of NAT Gateway IDs |
| <a name="output_nat_gateway_ips"></a> [nat\_gateway\_ips](#output\_nat\_gateway\_ips) | List of NAT Gateway Elastic IPs |
| <a name="output_private_network_acl_id"></a> [private\_network\_acl\_id](#output\_private\_network\_acl\_id) | Private Network ACL ID |
| <a name="output_private_route_table_ids"></a> [private\_route\_table\_ids](#output\_private\_route\_table\_ids) | List of Private Route Table IDs |
| <a name="output_private_subnet_availability_zones"></a> [private\_subnet\_availability\_zones](#output\_private\_subnet\_availability\_zones) | List of Private Subnet Availability Zones |
| <a name="output_private_subnet_cidr_blocks"></a> [private\_subnet\_cidr\_blocks](#output\_private\_subnet\_cidr\_blocks) | List of Private Subnet CIDR Blocks |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | List of Private Subnet IDs |
| <a name="output_public_network_acl_id"></a> [public\_network\_acl\_id](#output\_public\_network\_acl\_id) | Public Network ACL ID |
| <a name="output_public_route_table_id"></a> [public\_route\_table\_id](#output\_public\_route\_table\_id) | Public Route Table ID |
| <a name="output_public_subnet_availability_zones"></a> [public\_subnet\_availability\_zones](#output\_public\_subnet\_availability\_zones) | List of Public Subnet Availability Zones |
| <a name="output_public_subnet_cidr_blocks"></a> [public\_subnet\_cidr\_blocks](#output\_public\_subnet\_cidr\_blocks) | List of Public Subnet CIDR Blocks |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | List of Public Subnet IDs |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | VPC CIDR Block |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | VPC ID |

## Best Practices

### Resource Naming
- Use consistent naming patterns: `{project}-{environment}-{resource}`
- Example: `sre-dev-cluster`, `sre-prod-service`
- Avoid hardcoded names in favor of variable-driven naming

### Security
- Always use HTTPS-only configuration (port 443)
- Implement least-privilege IAM roles
- Use private subnets for application containers
- Enable ECR image scanning for vulnerability detection

### Infrastructure Management
- Deploy ECR repository first (core module)
- Use separate Terraform states for core vs application infrastructure
- Implement proper backend state management with S3 + DynamoDB
- Tag all resources consistently for cost tracking

### Monitoring & Logging
- Enable CloudWatch logging for troubleshooting
- Set appropriate log retention policies
- Monitor ECS service health and scaling metrics
- Use structured logging in applications

---

**Note**: This infrastructure is production-ready with HTTPS-only configuration, multi-AZ deployment, and comprehensive security controls. Adjust the configuration values in the tfvars files according to your specific requirements.
# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = var.ecs.cluster_name

  configuration {
    execute_command_configuration {
      logging = "DEFAULT"
    }
  }

  tags = merge(local.common_tags, {
    Name = var.ecs.cluster_name
  })
}

# KMS Key for CloudWatch Logs Encryption
resource "aws_kms_key" "cloudwatch_logs" {
  count                   = var.ecs.enable_logging ? 1 : 0
  description             = "KMS key for CloudWatch logs encryption"
  deletion_window_in_days = 7

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnEquals = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:${var.ecs.log_group_name}"
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.ecs.cluster_name}-cloudwatch-logs-key"
  })
}

# KMS Key Alias
resource "aws_kms_alias" "cloudwatch_logs" {
  count         = var.ecs.enable_logging ? 1 : 0
  name          = "alias/${var.ecs.cluster_name}-cloudwatch-logs"
  target_key_id = aws_kms_key.cloudwatch_logs[0].key_id
}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "ecs" {
  count             = var.ecs.enable_logging ? 1 : 0
  name              = var.ecs.log_group_name
  retention_in_days = var.ecs.log_retention_days
  kms_key_id        = aws_kms_key.cloudwatch_logs[0].arn

  tags = merge(local.common_tags, {
    Name = var.ecs.log_group_name
  })
}

# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.ecs.cluster_name}-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.ecs.cluster_name}-task-execution-role"
  })
}

# Attach AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Additional ECR permissions for ECS task execution role
resource "aws_iam_role_policy" "ecs_task_execution_ecr_policy" {
  count = var.ecs.enable_ecr ? 1 : 0
  name  = "${var.ecs.cluster_name}-ecr-policy"
  role  = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = [
          var.ecs.enable_ecr ? data.aws_ecr_repository.app[0].arn : "*",
          "*"
        ]
      }
    ]
  })
}

# ECS Task Role (for application permissions)
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.ecs.cluster_name}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.ecs.cluster_name}-task-role"
  })
}

# Security Group for ECS Tasks
resource "aws_security_group" "ecs_tasks" {
  name_prefix = "${var.ecs.cluster_name}-ecs-tasks"
  description = "Security group for ECS tasks (HTTPS)"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow HTTPS traffic from ALB"
    from_port       = var.ecs.container_port
    to_port         = var.ecs.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.ecs.cluster_name}-ecs-tasks-sg"
  })
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.ecs.cluster_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = merge(local.common_tags, {
    Name = "${var.ecs.cluster_name}-alb"
  })
}

# Security Group for ALB
resource "aws_security_group" "alb" {
  name_prefix = "${var.ecs.cluster_name}-alb"
  description = "Security group for Application Load Balancer (HTTPS only)"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.ecs.cluster_name}-alb-sg"
  })
}

# ALB Target Group
resource "aws_lb_target_group" "app" {
  name        = "${var.ecs.cluster_name}-tg"
  port        = var.ecs.container_port
  protocol    = "HTTPS"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTPS"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(local.common_tags, {
    Name = "${var.ecs.cluster_name}-tg"
  })
}

# ALB HTTPS Listener (HTTPS only)
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.ecs.ssl_policy
  certificate_arn   = var.ecs.certificate_arn != "" ? var.ecs.certificate_arn : data.aws_acm_certificate.main[0].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  tags = merge(local.common_tags, {
    Name = "${var.ecs.cluster_name}-https-listener"
  })
}

# ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = var.ecs.task_family
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs.cpu
  memory                   = var.ecs.memory

  container_definitions = jsonencode([
    {
      name      = var.ecs.container_name
      image     = var.ecs.enable_ecr ? "${data.aws_ecr_repository.app[0].repository_url}:latest" : var.ecs.container_image
      essential = true

      portMappings = [
        {
          containerPort = var.ecs.container_port
          hostPort      = var.ecs.container_port
          protocol      = "tcp"
        }
      ]

      logConfiguration = var.ecs.enable_logging ? {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs[0].name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      } : null

      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "PORT"
          value = tostring(var.ecs.container_port)
        }
      ]
    }
  ])

  tags = merge(local.common_tags, {
    Name = var.ecs.task_family
  })
}

# ECS Service
resource "aws_ecs_service" "main" {
  name            = var.ecs.service_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.ecs.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private[*].id
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = var.ecs.container_name
    container_port   = var.ecs.container_port
  }

  depends_on = [
    aws_lb_listener.https
  ]

  tags = merge(local.common_tags, {
    Name = var.ecs.service_name
  })
}

# Application Auto Scaling Target
resource "aws_appautoscaling_target" "ecs_target" {
  count              = var.ecs.enable_autoscaling ? 1 : 0
  max_capacity       = var.ecs.autoscaling_max_capacity
  min_capacity       = var.ecs.autoscaling_min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  depends_on = [aws_ecs_service.main]

  tags = merge(local.common_tags, {
    Name = "${var.ecs.service_name}-autoscaling-target"
  })
}

# Auto Scaling Policy - Scale Up
resource "aws_appautoscaling_policy" "ecs_scale_up" {
  count              = var.ecs.enable_autoscaling ? 1 : 0
  name               = "${var.ecs.service_name}-scale-up"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.ecs.autoscaling_cpu_target
    scale_in_cooldown  = var.ecs.autoscaling_scale_in_cooldown
    scale_out_cooldown = var.ecs.autoscaling_scale_out_cooldown
  }

  depends_on = [aws_appautoscaling_target.ecs_target]
}
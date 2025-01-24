provider "aws" {
  region = var.region
}

# ECS Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.cluster_name
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/${var.task_name}"
  retention_in_days = 30
}

# IAM Roles
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.task_name}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.task_name}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecs_task_rds_s3_policy" {
  name = "${var.task_name}-rds-s3-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # RDS IAM Authentication
      {
        Effect = "Allow",
        Action = [
          "rds-db:connect"
        ],
        Resource = var.rds_resource_arn
      },
      # S3 Write Access
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ],
        Resource = "${var.s3_bucket_arn}/*"
      }
    ]
  })
}

# ECS Task Definition
resource "aws_ecs_task_definition" "ecs_task" {
  family                   = var.task_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = templatefile("${path.module}/task_definition.json", {
    task_name    = var.task_name
    rds_endpoint = var.rds_endpoint
    rds_database = var.rds_database
    s3_bucket    = var.s3_bucket_arn
    region       = var.region
  })
}

# EventBridge Rule
resource "aws_cloudwatch_event_rule" "ecs_task_schedule" {
  name                = "${var.task_name}-schedule"
  description         = "Trigger ECS Task ${var.task_name} on a schedule"
  schedule_expression = var.schedule_expression
}

# EventBridge Target
resource "aws_cloudwatch_event_target" "ecs_task_target" {
  rule = aws_cloudwatch_event_rule.ecs_task_schedule.name
  arn  = aws_ecs_cluster.ecs_cluster.arn

  role_arn = aws_iam_role.ecs_task_execution_role.arn

  ecs_target {
    task_definition_arn = aws_ecs_task_definition.ecs_task.arn
    launch_type         = "FARGATE"

    network_configuration {
      subnets          = var.subnets
      security_groups  = var.security_groups
      assign_public_ip = false
    }
  }
}

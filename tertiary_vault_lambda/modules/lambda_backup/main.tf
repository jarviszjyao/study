###############################
# IAM Role 与内联策略（使用模板文件生成）
###############################

resource "aws_iam_role" "lambda_role" {
  name = "${var.lambda_function_name}_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = { Service = "lambda.amazonaws.com" }
      }
    ]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.lambda_function_name}_policy"
  role = aws_iam_role.lambda_role.id
  policy = templatefile("${path.module}/iam_policy.json.tpl", {
    s3_bucket       = var.s3_config.bucket_name,
    s3_kms_arn      = var.s3_config.s3_kms_arn,
    rds_db_resource_arn = var.rds_config.db_resource_arn,
    rds_kms_arn     = var.rds_config.kms_key_arn
  })
}

###############################
# Lambda Function 配置
###############################

resource "aws_lambda_function" "this" {
  function_name = var.lambda_function_name
  package_type  = "Image"
  image_uri     = var.image_uri
  role          = aws_iam_role.lambda_role.arn
  timeout       = var.function_timeout
  memory_size   = var.function_memory_size

  # 指定临时存储大小（/tmp）
  ephemeral_storage {
    size = var.ephemeral_storage_size
  }

  # VPC 部署
  vpc_config {
    subnet_ids         = var.vpc_config.subnet_ids
    security_group_ids = var.vpc_config.security_group_ids
  }

  # 性能相关设置：架构、预留并发、X-Ray 追踪
  architectures = var.lambda_performance.architectures
  reserved_concurrent_executions = var.lambda_performance.reserved_concurrent_executions
  tracing_config {
    mode = var.lambda_performance.tracing_mode
  }

  # 环境变量传递 RDS 与 S3 的必要信息
  environment {
    variables = {
      RDS_ENDPOINT = var.rds_config.endpoint,
      RDS_DB_NAME  = var.rds_config.db_name,
      RDS_DB_PORT  = tostring(var.rds_config.db_port),
      DB_USERNAME  = var.rds_config.db_username,
      S3_BUCKET    = var.s3_config.bucket_name
    }
  }

  tags = var.tags
}

###############################
# EventBridge 定时触发配置（每天一次）
###############################

resource "aws_cloudwatch_event_rule" "lambda_schedule" {
  name                = "${var.lambda_function_name}_schedule_rule"
  schedule_expression = var.event_schedule
  description         = "定时触发 Lambda 导出数据任务"
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.lambda_schedule.name
  target_id = "lambda"
  arn       = aws_lambda_function.this.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_schedule.arn
}

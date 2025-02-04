###############################
# IAM Role 与策略配置
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
    s3_bucket           = var.s3_config.bucket_name,
    rds_kms_key_arn     = var.rds_config.kms_key_arn,
    s3_kms_key_arn      = var.s3_config.s3_kms_arn,
    rds_db_resource_arn = var.rds_config.db_resource_arn
  })
}

###############################
# Lambda 函数配置
###############################

resource "aws_lambda_function" "this" {
  function_name = var.lambda_function_name
  package_type  = "Image"
  image_uri     = var.image_uri
  role          = aws_iam_role.lambda_role.arn
  timeout       = var.function_timeout
  memory_size   = var.function_memory_size

  # 指定容器部署时所在的 VPC 配置
  vpc_config {
    subnet_ids         = var.vpc_config.subnet_ids
    security_group_ids = var.vpc_config.security_group_ids
  }

  # 性能配置：支持指定架构（例如 "arm64" 用于 Graviton）、预留并发和追踪模式
  architectures = var.lambda_performance.architectures
  reserved_concurrent_executions = var.lambda_performance.reserved_concurrent_executions
  tracing_config {
    mode = var.lambda_performance.tracing_mode
  }

  environment {
    variables = {
      RDS_ENDPOINT = var.rds_config.endpoint,
      RDS_DB_NAME  = var.rds_config.db_name,
      RDS_DB_PORT  = tostring(var.rds_config.db_port),
      S3_BUCKET    = var.s3_config.bucket_name,
      RDS_KMS_KEY  = var.rds_config.kms_key_arn,
      S3_KMS_KEY   = var.s3_config.s3_kms_arn
    }
  }

  tags = var.tags
}

###############################
# EventBridge 定时触发配置
###############################

resource "aws_cloudwatch_event_rule" "lambda_schedule" {
  name                = "${var.lambda_function_name}_schedule_rule"
  schedule_expression = var.event_schedule
  description         = "定时触发 Lambda 执行 RDS 备份任务"
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

###############################
# Lambda 监控报警（可选）
###############################

resource "aws_cloudwatch_metric_alarm" "lambda_error_alarm" {
  count               = var.lambda_monitoring.error_alarm_enabled ? 1 : 0
  alarm_name          = "${var.lambda_function_name}_error_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = var.lambda_monitoring.error_alarm_period
  statistic           = "Sum"
  threshold           = var.lambda_monitoring.error_threshold
  alarm_description   = "当 Lambda 错误数量超过阈值时报警"
  dimensions = {
    FunctionName = aws_lambda_function.this.function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_duration_alarm" {
  count               = var.lambda_monitoring.duration_alarm_enabled ? 1 : 0
  alarm_name          = "${var.lambda_function_name}_duration_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = var.lambda_monitoring.duration_alarm_period
  statistic           = "Average"
  threshold           = var.lambda_monitoring.duration_threshold
  alarm_description   = "当 Lambda 平均执行时长超过阈值时报警"
  dimensions = {
    FunctionName = aws_lambda_function.this.function_name
  }
}

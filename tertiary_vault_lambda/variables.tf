variable "aws_region" {
  description = "部署资源的 AWS 区域"
  type        = string
  default     = "us-east-1"
}

variable "lambda_function_name" {
  description = "Lambda 函数名称"
  type        = string
}

variable "image_uri" {
  description = "Lambda 使用的 ECR 镜像 URI"
  type        = string
}

variable "vpc_config" {
  description = "VPC 网络配置"
  type = object({
    vpc_id             = string
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
}

variable "rds_config" {
  description = "RDS 数据库配置"
  type = object({
    endpoint        = string
    db_name         = string
    db_port         = number
    iam_auth        = bool
    kms_key_arn     = string
    db_resource_arn = string
  })
}

variable "s3_config" {
  description = "S3 存储桶配置"
  type = object({
    bucket_name = string
    s3_kms_arn  = string
  })
}

variable "lambda_performance" {
  description = "Lambda 性能配置，如架构、预留并发数和追踪设置"
  type = object({
    architectures                 = list(string)
    reserved_concurrent_executions = number
    tracing_mode                  = string
  })
  default = {
    architectures = ["x86_64"]
    reserved_concurrent_executions = null
    tracing_mode = "PassThrough"
  }
}

variable "lambda_monitoring" {
  description = "Lambda 监控报警配置"
  type = object({
    error_alarm_enabled    = bool
    error_threshold        = number
    error_alarm_period     = number
    duration_alarm_enabled = bool
    duration_threshold     = number
    duration_alarm_period  = number
  })
  default = {
    error_alarm_enabled    = false
    error_threshold        = 1
    error_alarm_period     = 300
    duration_alarm_enabled = false
    duration_threshold     = 10000
    duration_alarm_period  = 300
  }
}

variable "event_schedule" {
  description = "EventBridge 定时规则表达式"
  type        = string
  default     = "rate(1 day)"
}

variable "tags" {
  description = "资源 Tags"
  type        = map(string)
  default     = {}
}

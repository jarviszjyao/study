variable "lambda_function_name" {
  description = "Lambda 函数的名称"
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
    endpoint        = string    # 数据库访问端点
    db_name         = string    # 数据库名称
    db_port         = number    # 数据库端口
    iam_auth        = bool      # 是否使用 IAM 认证
    kms_key_arn     = string    # 数据库访问使用的 KMS Key ARN
    db_resource_arn = string    # 用于 IAM 认证连接的 RDS 资源 ARN
  })
}

variable "s3_config" {
  description = "S3 存储桶配置"
  type = object({
    bucket_name = string
    s3_kms_arn  = string    # S3 使用的 KMS Key ARN
  })
}

variable "lambda_performance" {
  description = "Lambda 性能配置，如架构、预留并发数和追踪设置"
  type = object({
    architectures                 = list(string)  # 如 ["x86_64"] 或 ["arm64"]
    reserved_concurrent_executions = number        # 若为 null，则表示不设置限制
    tracing_mode                  = string        # 如 "Active" 或 "PassThrough"
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
  description = "EventBridge 定时规则表达式（例如：rate(1 day)）"
  type        = string
  default     = "rate(1 day)"
}

variable "tags" {
  description = "资源 Tags"
  type        = map(string)
  default     = {}
}

variable "function_timeout" {
  description = "Lambda 函数超时时间（秒）"
  type        = number
  default     = 900
}

variable "function_memory_size" {
  description = "Lambda 函数内存大小（MB）"
  type        = number
  default     = 1024
}

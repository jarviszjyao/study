variable "lambda_function_name" {
  description = "Lambda 函数名称，可自定义"
  type        = string
}

variable "image_uri" {
  description = "Lambda 使用的 ECR 镜像 URI"
  type        = string
}

variable "ephemeral_storage_size" {
  description = "Lambda 临时存储大小（/tmp），单位 MB（最大 10240），默认 512MB"
  type        = number
  default     = 512
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
  description = "RDS 数据库配置，用于 IAM 认证连接，及其加密相关信息"
  type = object({
    endpoint        = string    # RDS 实例访问端点
    db_name         = string    # 数据库名称
    db_port         = number    # 数据库端口
    db_username     = string    # 数据库用户名称（使用 IAM 类型的 DB 用户）
    db_resource_arn = string    # 用于 rds-db:connect 的资源 ARN
    kms_key_arn     = string    # RDS 使用的 KMS CMK ARN
  })
}

variable "s3_config" {
  description = "S3 存储桶配置及其加密相关信息"
  type = object({
    bucket_name = string    # S3 桶名称
    s3_kms_arn  = string    # S3 使用的 KMS CMK ARN
  })
}

variable "lambda_performance" {
  description = "Lambda 性能配置，包括架构、预留并发数、X-Ray 追踪模式"
  type = object({
    architectures                 = list(string)  # 如 ["x86_64"] 或 ["arm64"]
    reserved_concurrent_executions = number        # 若为 null 则表示不限制
    tracing_mode                  = string        # "Active" 或 "PassThrough"
  })
  default = {
    architectures                 = ["x86_64"]
    reserved_concurrent_executions = null
    tracing_mode                  = "PassThrough"
  }
}

variable "event_schedule" {
  description = "EventBridge 定时规则表达式（例如：rate(1 day)）"
  type        = string
  default     = "rate(1 day)"
}

variable "function_timeout" {
  description = "Lambda 超时时间（秒）"
  type        = number
  default     = 900
}

variable "function_memory_size" {
  description = "Lambda 内存容量（MB）"
  type        = number
  default     = 1024
}

variable "tags" {
  description = "资源 Tags"
  type        = map(string)
  default     = {}
}

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

variable "ephemeral_storage_size" {
  description = "Lambda 临时存储大小，单位 MB"
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
  description = "RDS 数据库配置（使用 IAM 认证）及加密所需的 KMS CMK ARN"
  type = object({
    endpoint        = string
    db_name         = string
    db_port         = number
    db_username     = string
    db_resource_arn = string
    kms_key_arn     = string
  })
}

variable "s3_config" {
  description = "S3 存储桶配置及其使用的 KMS CMK ARN"
  type = object({
    bucket_name = string
    s3_kms_arn  = string
  })
}

variable "lambda_performance" {
  description = "Lambda 性能配置"
  type = object({
    architectures                 = list(string)
    reserved_concurrent_executions = number
    tracing_mode                  = string
  })
  default = {
    architectures                 = ["x86_64"]
    reserved_concurrent_executions = null
    tracing_mode                  = "PassThrough"
  }
}

variable "event_schedule" {
  description = "EventBridge 定时规则表达式"
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

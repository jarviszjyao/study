variable "region" {
  description = "AWS region"
}

variable "cluster_name" {
  description = "ECS Cluster Name"
}

variable "task_name" {
  description = "ECS Task Name"
}

variable "schedule_expression" {
  description = "EventBridge schedule expression (e.g., cron)"
}

variable "rds_endpoint" {
  description = "RDS Endpoint"
}

variable "rds_database" {
  description = "RDS Database Name"
}

variable "rds_resource_arn" {
  description = "RDS Resource ARN for IAM Authentication"
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
}

variable "subnets" {
  description = "Subnets for ECS Task networking"
  type        = list(string)
}

variable "security_groups" {
  description = "Security groups for ECS Task networking"
  type        = list(string)
}

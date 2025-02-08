aws_region           = "us-east-1"
lambda_function_name = "rds_backup_lambda"
image_uri            = "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-backup-image:latest"

vpc_config = {
  vpc_id             = "vpc-abcde123"
  subnet_ids         = ["subnet-12345678", "subnet-87654321"]
  security_group_ids = ["sg-12345678"]
}

rds_config = {
  endpoint        = "rds-instance.abc123.us-east-1.rds.amazonaws.com"
  db_name         = "mydatabase"
  db_port         = 5432
  iam_auth        = true
  kms_key_arn     = "arn:aws:kms:us-east-1:123456789012:key/rds-key"
  db_resource_arn = "arn:aws:rds-db:us-east-1:123456789012:dbuser:db-ABCDEFGHIJKLMNOP/mydbuser"
}

s3_config = {
  bucket_name = "my-backup-bucket"
  s3_kms_arn  = "arn:aws:kms:us-east-1:123456789012:key/s3-key"
}

lambda_performance = {
  architectures                 = ["arm64"]         # 使用 Graviton 架构
  reserved_concurrent_executions = null              # 不设置预留并发，使用默认
  tracing_mode                  = "Active"          # 开启 X-Ray 追踪
}

lambda_monitoring = {
  error_alarm_enabled    = true
  error_threshold        = 1
  error_alarm_period     = 300
  duration_alarm_enabled = true
  duration_threshold     = 10000
  duration_alarm_period  = 300
}

event_schedule = "rate(1 day)"

tags = {
  Environment = "production"
  Project     = "rds-backup"
}

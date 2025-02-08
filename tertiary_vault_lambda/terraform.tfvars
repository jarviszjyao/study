aws_region           = "us-east-1"
lambda_function_name = "rds_backup_lambda"
image_uri            = "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-backup-image:latest"
ephemeral_storage_size = 1024

vpc_config = {
  vpc_id             = "vpc-abcde123"
  subnet_ids         = ["subnet-12345678", "subnet-87654321"]
  security_group_ids = ["sg-12345678"]
}

rds_config = {
  endpoint        = "rds-instance.abc123.us-east-1.rds.amazonaws.com"
  db_name         = "mydatabase"
  db_port         = 5432
  db_username     = "mydbuser"
  db_resource_arn = "arn:aws:rds-db:us-east-1:123456789012:dbuser:db-ABCDEFGHIJKLMNOP/mydbuser"
  kms_key_arn     = "arn:aws:kms:us-east-1:123456789012:key/rds-key"
}

s3_config = {
  bucket_name = "my-backup-bucket"
  s3_kms_arn  = "arn:aws:kms:us-east-1:123456789012:key/s3-key"
}

lambda_performance = {
  architectures                 = ["arm64"]   # 使用 Graviton 架构
  reserved_concurrent_executions = null
  tracing_mode                  = "Active"    # 开启 X-Ray 追踪
}

event_schedule = "rate(1 day)"
function_timeout     = 900
function_memory_size = 1024

tags = {
  Environment = "production"
  Project     = "rds-backup"
}

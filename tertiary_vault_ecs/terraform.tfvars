region               = "us-east-1"
cluster_name         = "pg-dump-cluster"
task_name            = "pg-dump-task"
schedule_expression  = "cron(0 2 * * ? *)"
rds_endpoint         = "your-rds-endpoint"
rds_database         = "your-database"
rds_resource_arn     = "arn:aws:rds:us-east-1:123456789012:db:my-instance"
s3_bucket_arn        = "arn:aws:s3:::your-s3-bucket"
subnets              = ["subnet-12345678", "subnet-87654321"]
security_groups      = ["sg-12345678"]

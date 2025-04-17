# 必需的 S3 后端配置
bucket         = "terraform-state-company-name"
key            = "nat-gateway/terraform.tfstate"
region         = "eu-west-1"
encrypt        = true
dynamodb_table = "terraform-locks"

# 可选：如果需要显式设置凭证（通常不推荐）
# access_key    = "YOUR_AWS_ACCESS_KEY"
# secret_key    = "YOUR_AWS_SECRET_KEY"

# 可选：使用 IAM 角色进行跨账户访问
# role_arn      = "arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME"
# session_name  = "terraform-backend-session"
# external_id   = "YOUR_EXTERNAL_ID"  # 如果角色需要

# 可选：配置 S3 端点和其他高级选项
# endpoint              = "s3.REGION.amazonaws.com"
# skip_credentials_validation = false
# skip_region_validation     = false

# 可选：设置最大并行操作数和超时时间
# max_retries = 5

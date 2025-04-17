# 开发环境的 S3 后端配置
bucket         = "terraform-state-dev-account"
key            = "nat-gateway/dev/terraform.tfstate"
region         = "eu-west-1"
encrypt        = true
dynamodb_table = "terraform-locks-dev"

# 开发环境通常使用 AWS 配置文件
# profile        = "dev-account"

# 开发环境可能使用自定义endpoint（如本地或私有S3接口）
# endpoint       = "s3.eu-west-1.amazonaws.com"

# 开发环境可能启用额外调试信息
# 注意：生产环境应禁用
skip_credentials_validation = false
skip_metadata_api_check     = false
force_path_style            = false 
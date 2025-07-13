# AWS Bedrock Terraform 部署指南

## 前置条件

### 1. 环境准备
- AWS CLI 已配置
- Terraform >= 1.3.0 已安装
- 具有适当权限的 AWS 账户

### 2. 基础设施要求
- 已存在的 VPC
- 私有子网（用于 Bedrock 部署）
- 可路由子网（连接到内网）
- S3 存储桶（用于 Terraform state）

## 部署步骤

### 1. 配置 S3 Backend
编辑 `main/main.tf` 中的 backend 配置：
```hcl
backend "s3" {
  bucket = "your-actual-tfstate-bucket"
  key    = "bedrock/terraform.tfstate"
  region = "ap-northeast-1"
  # 可选：启用 DynamoDB 锁
  # dynamodb_table = "terraform-locks"
}
```

### 2. 配置环境变量
根据您的环境选择对应的 `.tfvars` 文件：

#### 开发环境
```bash
cd main
terraform plan -var-file="../environments/dev.tfvars"
```

#### 生产环境
```bash
cd main
terraform plan -var-file="../environments/prod.tfvars"
```

### 3. 自定义配置
编辑对应的 `.tfvars` 文件，更新以下参数：
- `vpc_id`: 您的 VPC ID
- `private_subnet_ids`: 私有子网 ID 列表
- `bedrock_model_id`: 选择的模型 ID
- `vpc_endpoint_security_group_ids`: 安全组 ID

### 4. 初始化 Terraform
```bash
cd main
terraform init
```

### 5. 验证配置
```bash
terraform plan -var-file="../environments/dev.tfvars"
```

### 6. 部署资源
```bash
terraform apply -var-file="../environments/dev.tfvars"
```

### 7. 验证部署
```bash
terraform output
```

## 使用示例

### 1. 通过 AWS CLI 测试
```bash
# 获取 VPC Endpoint DNS
aws bedrock invoke-model \
  --model-id anthropic.claude-3-sonnet-20240229-v1:0 \
  --body '{"prompt": "Hello, how are you?", "max_tokens": 100}' \
  --endpoint-url https://your-vpc-endpoint-id.bedrock.ap-northeast-1.amazonaws.com
```

### 2. 通过 Python SDK 测试
```python
import boto3

bedrock = boto3.client(
    service_name='bedrock-runtime',
    endpoint_url='https://your-vpc-endpoint-id.bedrock.ap-northeast-1.amazonaws.com',
    region_name='ap-northeast-1'
)

response = bedrock.invoke_model(
    modelId='anthropic.claude-3-sonnet-20240229-v1:0',
    body='{"prompt": "Hello, how are you?", "max_tokens": 100}'
)
```

## 监控和维护

### 1. 查看资源状态
```bash
terraform show
terraform state list
```

### 2. 更新配置
```bash
# 修改 .tfvars 文件后
terraform plan -var-file="../environments/dev.tfvars"
terraform apply -var-file="../environments/dev.tfvars"
```

### 3. 销毁资源
```bash
terraform destroy -var-file="../environments/dev.tfvars"
```

## 故障排除

### 1. 常见错误
- **权限不足**: 检查 IAM 角色权限
- **VPC 配置错误**: 确认子网配置
- **模型不可用**: 检查模型 ID 和区域

### 2. 调试命令
```bash
# 查看详细日志
terraform plan -var-file="../environments/dev.tfvars" -detailed-exitcode

# 查看状态
terraform state show aws_vpc_endpoint.bedrock
```

### 3. 获取帮助
- AWS Bedrock 文档: https://docs.aws.amazon.com/bedrock/
- Terraform AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs

## 安全最佳实践

### 1. 网络安全
- 使用私有子网部署
- 配置适当的安全组规则
- 启用 VPC Flow Logs

### 2. 访问控制
- 使用最小权限原则
- 定期轮换访问密钥
- 启用 CloudTrail 审计

### 3. 数据保护
- 加密传输和存储
- 实施数据分类
- 定期备份配置

## 成本优化

### 1. 模型选择
- 开发环境使用较小模型
- 生产环境根据需求选择
- 监控使用量和成本

### 2. 参数优化
- 合理设置 max_tokens
- 优化 temperature 参数
- 使用适当的停止序列

### 3. 监控告警
- 设置成本告警
- 监控 API 调用频率
- 跟踪资源使用情况 
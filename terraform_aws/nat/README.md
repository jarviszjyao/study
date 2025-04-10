# AWS NAT Gateway Terraform 模块

本项目提供了一套完整的 Terraform 代码，用于在 AWS 中创建和维护 NAT Gateway 资源，特别适用于通过 Direct Connect 连接到内网的环境。

## 目录结构

```
terraform_aws/nat/
├── environments/               # 环境配置目录
│   ├── main.tf                 # 调用 NAT Gateway 模块的主配置
│   ├── variables.tf            # 环境级别的变量定义
│   ├── terraform.tfvars        # 具体变量值
│   └── terraform_backend.tfvars # 远程状态后端配置
└── modules/                    # 模块目录
    └── nat_gateway/            # NAT Gateway 模块
        ├── main.tf             # 模块主配置
        ├── variables.tf        # 模块变量定义
        └── outputs.tf          # 模块输出变量
```

## 功能特点

- 支持在多个可用区部署 NAT Gateway 以实现高可用
- 支持单个 NAT Gateway 模式以降低成本
- 自动检测 VPC 中的子网并按可用区分组
- 为私有子网创建路由表和路由规则
- 可灵活配置目标 CIDR 范围

## 远程状态后端配置

该项目使用 S3 作为远程状态后端。后端配置参数存储在 `environments/terraform_backend.tfvars` 文件中：

```hcl
bucket         = "terraform-state-company-name"
key            = "nat-gateway/terraform.tfstate"
region         = "eu-west-1"
encrypt        = true
dynamodb_table = "terraform-locks"
```

而在 `environments/main.tf` 中的后端配置保持简洁：

```hcl
terraform {
  backend "s3" {}
}
```

请根据您的实际情况修改 `terraform_backend.tfvars` 文件中的以下值：
- `bucket`: S3 存储桶名称
- `key`: 状态文件路径前缀
- `region`: AWS 区域
- `dynamodb_table`: 用于状态锁定的 DynamoDB 表名

## 使用说明

1. 修改 `environments/terraform.tfvars` 文件，设置您的环境特定变量：
   - `vpc_id`: 您的 VPC ID
   - `environment`: 环境名称 (prod, staging, dev 等)
   - `project`: 项目名称
   - `destination_cidr_block`: 目标 CIDR 范围

2. 初始化 Terraform 并应用配置：
   ```bash
   cd environments
   terraform init -backend-config=terraform_backend.tfvars
   terraform plan
   terraform apply
   ```

## 注意事项

- 确保 VPC 中的子网已经正确标记了 `Type` 标签（"Routable" 或 "Private"）
- 确保已创建 S3 存储桶和 DynamoDB 表用于远程状态存储
- 初始化时必须使用 `-backend-config` 参数指定后端配置文件
- NAT Gateway 会产生费用，请确保了解成本影响 
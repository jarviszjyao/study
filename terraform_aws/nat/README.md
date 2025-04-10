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
- 支持同时路由多个 CIDR 块
- 可选择性使用现有路由表而非创建新表
- 内置健壮的错误检查和验证机制
- 资源生命周期管理，确保安全部署

## 部署架构

本模块支持两种部署模式：

### 1. 高可用模式（默认）

每个可用区部署一个 NAT Gateway，确保单个 AZ 故障不会影响整个系统。

```
                      ┌───────────────┐
                      │      VPC      │
                      └───────────────┘
                             │
           ┌─────────────────┼─────────────────┐
           │                 │                 │
    ┌──────▼──────┐   ┌──────▼──────┐   ┌──────▼──────┐
    │     AZ-a    │   │     AZ-b    │   │     AZ-c    │
    └─────────────┘   └─────────────┘   └─────────────┘
           │                 │                 │
    ┌──────▼──────┐   ┌──────▼──────┐   ┌──────▼──────┐
    │ NAT Gateway │   │ NAT Gateway │   │ NAT Gateway │
    └─────────────┘   └─────────────┘   └─────────────┘
           │                 │                 │
    ┌──────▼──────┐   ┌──────▼──────┐   ┌──────▼──────┐
    │Private Route│   │Private Route│   │Private Route│
    │   Table     │   │   Table     │   │   Table     │
    └─────────────┘   └─────────────┘   └─────────────┘
           │                 │                 │
    ┌──────▼──────┐   ┌──────▼──────┐   ┌──────▼──────┐
    │Private Subnet│   │Private Subnet│   │Private Subnet│
    └─────────────┘   └─────────────┘   └─────────────┘
```

### 2. 低成本模式

单个 NAT Gateway 为所有私有子网提供服务，降低成本但引入单点故障风险。

```
                      ┌───────────────┐
                      │      VPC      │
                      └───────────────┘
                             │
           ┌─────────────────┼─────────────────┐
           │                 │                 │
    ┌──────▼──────┐   ┌──────▼──────┐   ┌──────▼──────┐
    │     AZ-a    │   │     AZ-b    │   │     AZ-c    │
    └─────────────┘   └─────────────┘   └─────────────┘
           │
    ┌──────▼──────┐
    │ NAT Gateway │
    └─────────────┘
           │
           ├─────────────────┬─────────────────┐
           │                 │                 │
    ┌──────▼──────┐   ┌──────▼──────┐   ┌──────▼──────┐
    │Private Route│   │Private Route│   │Private Route│
    │   Table     │   │   Table     │   │   Table     │
    └─────────────┘   └─────────────┘   └─────────────┘
           │                 │                 │
    ┌──────▼──────┐   ┌──────▼──────┐   ┌──────▼──────┐
    │Private Subnet│   │Private Subnet│   │Private Subnet│
    └─────────────┘   └─────────────┘   └─────────────┘
```

## 路由表管理选项

本模块提供两种路由表管理模式：

### 1. 创建新路由表（默认）

默认情况下，模块会为每个私有子网创建一个新的路由表：

```
┌────────────────┐         ┌────────────────┐
│  NAT Gateway   │─────────▶   新路由表     │
└────────────────┘         └────────────────┘
                                   │
                           ┌───────▼───────┐
                           │   私有子网    │
                           └───────────────┘
```

### 2. 使用现有路由表

如果您已经有路由表，并希望只添加 NAT Gateway 路由，可以选择使用现有路由表：

```
┌────────────────┐         ┌────────────────┐
│  NAT Gateway   │─────────▶  现有路由表    │
└────────────────┘         └────────────────┘
                                   │
                           ┌───────▼───────┐
                           │   私有子网    │
                           └───────────────┘
```

### 3. 多目标 CIDR 路由

您可以配置多个 CIDR 块通过同一个 NAT Gateway 路由:

```
┌────────────────┐         ┌────────────────┐
│                │──10.0.0.0/8──▶           │
│  NAT Gateway   │         │    路由表     │
│                │──172.16.0.0/12▶          │
└────────────────┘         └────────────────┘
```

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

### 基本使用

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

### 高可用配置示例

高可用配置将在每个可用区部署一个 NAT Gateway:

```hcl
# terraform.tfvars
region              = "eu-west-1"
vpc_id              = "vpc-01234567890abcdef"
environment         = "prod"
project             = "core-network"
single_nat_gateway  = false
destination_cidr_block = "0.0.0.0/0"  # 互联网访问
```

### 低成本配置示例

低成本配置将只部署一个 NAT Gateway:

```hcl
# terraform.tfvars
region              = "eu-west-1"
vpc_id              = "vpc-01234567890abcdef"
environment         = "dev"
project             = "test-network"
single_nat_gateway  = true  # 只部署一个 NAT Gateway
destination_cidr_block = "10.0.0.0/8"  # 内网访问
```

### 多 CIDR 路由配置示例

如果需要通过 NAT Gateway 路由到多个目标 CIDR 范围:

```hcl
# terraform.tfvars
destination_cidr_block = "10.0.0.0/8"  # 主要内网 CIDR 范围
additional_route_cidr_blocks = [
  "172.16.0.0/12",  # 额外的内网 CIDR 范围
  "192.168.0.0/16"  # 另一个额外的内网 CIDR 范围
]
```

### 使用现有路由表示例

如果您想使用现有的路由表而不是创建新的:

```hcl
# terraform.tfvars
create_private_route_tables = false
existing_private_route_table_ids = [
  "rtb-0123456789abcdef1",  # AZ-1 的路由表
  "rtb-0123456789abcdef2"   # AZ-2 的路由表
]
```

## 子网标签要求

本模块使用子网标签来识别不同类型的子网。请确保您的子网使用以下标签：

- 路由子网 (可访问外部网络的子网): `Type = "Routable"`
- 私有子网 (内部资源所在子网): `Type = "Private"`

如果您的子网使用不同的标签，请修改 `environments/main.tf` 中的过滤条件。

## 安全最佳实践

1. **最小权限**: 使用具有最小权限的 IAM 角色运行 Terraform
   
   ```hcl
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "ec2:*NatGateway*",
           "ec2:*RouteTable*",
           "ec2:*Route*",
           "ec2:*Address*",
           "ec2:*Subnet*",
           "ec2:*Vpc*",
           "ec2:*Tag*"
         ],
         "Resource": "*"
       }
     ]
   }
   ```

2. **加密**: 确保远程状态文件始终保持加密状态
3. **版本控制**: 使用 Git 或其他版本控制系统跟踪配置变更
4. **开启流日志**: 考虑为 NAT Gateway 配置 VPC 流日志以监控流量

## 成本考量

NAT Gateway 会产生持续的费用，主要包括：

- 每小时固定运行费用
- 数据处理费用
- 弹性 IP 静态分配费用

使用单个 NAT Gateway 可以降低成本约 2/3（在三个 AZ 的情况下），但会减少可用性。

## 故障排除

常见问题：

1. **子网无法找到**: 确保子网已正确标记 `Type` 标签
2. **路由未生效**: 检查安全组和网络 ACL 规则
3. **初始化错误**: 确保 S3 存储桶和 DynamoDB 表已经创建
4. **路由表问题**: 当使用现有路由表时，确保提供了正确数量的路由表 ID

## 贡献和支持

如需贡献或报告问题，请通过内部通道与云基础设施团队联系。 
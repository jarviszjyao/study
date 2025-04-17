# AWS EFS Terraform Module

这个Terraform模块用于创建和管理AWS弹性文件系统(EFS)资源，提供了安全、高可用性和可扩展的文件存储解决方案，专为VPC内部应用提供共享存储。

## 架构图

```
+----------------------------------+
|            VPC                   |
|                                  |
| +------------+    +------------+ |
| | Private    |    | Private    | |
| | Subnet 1   |    | Subnet 2   | |
| | (AZ-a)     |    | (AZ-b)     | |
| |            |    |            | |
| | +--------+ |    | +--------+ | |
| | |        | |    | |        | | |
| | |  EC2   | |    | |  EC2   | | |
| | |Instance| |    | |Instance| | |
| | |        | |    | |        | | |
| | +---+----+ |    | +---+----+ | |
| |     |      |    |     |      | |
| |     |      |    |     |      | |
| |     v      |    |     v      | |
| | +---+----+ |    | +---+----+ | |
| | |EFS Mount| |    | |EFS Mount| | |
| | |Target   +-------->Target   | | |
| | |         | |    | |         | | |
| | +----+----+ |    | +----+----+ | |
| |      |      |    |      |      | |
| +------|------+    +------|------+ |
|        |                  |        |
|        v                  v        |
|    +---+------------------+---+    |
|    |      Security Group      |    |
|    |  (Controls EFS Access)   |    |
|    +---+------------------+---+    |
|        |                  |        |
|        v                  v        |
|    +---+------------------+---+    |
|    |                          |    |
|    |    EFS File System       |    |
|    |                          |    |
|    +--------------------------+    |
|                |                   |
|                v                   |
|    +--------------------------+    |
|    |    VPC Endpoint (EFS)    |    |
|    +--------------------------+    |
|                                    |
+------------------------------------+
```

## 主要特性

- **高可用性**: 跨多个可用区部署EFS挂载点
- **安全性**:
  - 仅限VPC内部访问，无互联网连接需求
  - 强制启用Root Squashing，防止root权限滥用
  - 为不同业务域创建隔离的访问点
  - 支持EFS加密（传输中和静态数据）
- **灵活性**:
  - 支持使用现有VPC和子网
  - 自定义安全组规则
  - 可配置的性能和吞吐量模式
- **生命周期管理**:
  - 支持自动备份
  - 配置数据生命周期策略（如IA存储类别转换）

## 安全合规特性

1. **强制Root Squashing**: 限制root用户访问，防止权限提升风险
2. **业务域隔离**: 每个业务域/功能使用唯一的访问点，遵循最小权限原则
3. **精细的访问控制**: 通过POSIX权限和安全组规则控制文件系统访问
4. **纯VPC内部通信**: 无需互联网访问，增强安全性
5. **加密**: 支持传输中和静态数据加密

## 使用方法

### 基本用法

```hcl
module "efs" {
  source = "./modules/efs"

  name               = "my-efs"
  vpc_id             = "vpc-12345678"
  subnet_ids         = ["subnet-1a2b3c4d", "subnet-5e6f7g8h"]
  security_group_id  = module.security_group.sg_id
  
  # 启用Root Squashing
  enforce_root_squashing = true
  
  # 配置业务域隔离的访问点
  access_points = {
    finance = {
      posix_user = {
        uid = 1000
        gid = 1000
      }
      root_directory = {
        path = "/finance"
        creation_info = {
          owner_uid   = 1000
          owner_gid   = 1000
          permissions = "750"
        }
      }
    }
  }
  
  # 区域设置
  region = "us-east-1"
}
```

### 安全组创建

```hcl
module "security_group" {
  source = "git::https://your-repo-url/security-group-module"
  
  description = "Security group for EFS"
  vpc_id = "vpc-12345678"
  
  sg_ingress_rules = [
    {
      from_port   = 2049
      to_port     = 2049
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
      description = "NFS from within VPC"
    }
  ]
  
  sg_egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["10.0.0.0/16"]
      description = "All traffic within VPC only"
    }
  ]
}
```

### 使用现有的VPC端点

```hcl
module "efs" {
  source = "./modules/efs"
  
  # ... 其他配置 ...
  
  # 引用现有的VPC端点
  existing_vpc_endpoint_id = "vpce-12345678"
}
```

## 输入变量

### 必需参数

| 参数名 | 描述 |
|--------|------|
| `name` | EFS资源名称 |
| `vpc_id` | VPC ID |
| `subnet_ids` | 子网ID列表，用于创建EFS挂载点 |
| `region` | AWS区域 |

### 安全相关参数

| 参数名 | 描述 | 默认值 |
|--------|------|--------|
| `security_group_id` | 安全组ID，用于控制对EFS的访问 | `null` |
| `encrypted` | 是否启用EFS加密 | `true` |
| `kms_key_id` | 用于加密的KMS密钥ID | `null` (使用默认KMS密钥) |
| `enforce_root_squashing` | 是否启用Root Squashing | `true` |
| `file_system_policy` | 自定义文件系统策略 | `null` |
| `use_default_policy` | 是否使用默认策略 | `false` |

### 性能相关参数

| 参数名 | 描述 | 默认值 |
|--------|------|--------|
| `performance_mode` | 性能模式 (`generalPurpose`或`maxIO`) | `generalPurpose` |
| `throughput_mode` | 吞吐量模式 (`bursting`, `provisioned`, 或 `elastic`) | `bursting` |
| `provisioned_throughput_in_mibps` | 预置吞吐量 (MiB/s) | `null` |

### 生命周期参数

| 参数名 | 描述 | 默认值 |
|--------|------|--------|
| `lifecycle_policy` | 生命周期策略映射 | `{}` |
| `enable_backup` | 是否启用备份 | `true` |

### 访问点参数

| 参数名 | 描述 | 默认值 |
|--------|------|--------|
| `access_points` | 访问点定义映射 | `{}` |

有关完整的参数列表，请参考模块中的`variables.tf`文件。

## 输出值

| 输出名 | 描述 |
|--------|------|
| `id` | EFS文件系统ID |
| `arn` | EFS文件系统ARN |
| `dns_name` | EFS文件系统DNS名称 |
| `mount_targets` | EFS挂载点映射 |
| `mount_target_ips` | 挂载点IP地址列表 |
| `mount_target_dns_names` | 挂载点DNS名称列表 |
| `access_points` | 访问点映射 |
| `access_point_dns_names` | 访问点DNS名称映射 |

## EC2实例挂载示例

以下是如何在EC2实例上挂载EFS文件系统的示例用户数据脚本:

```bash
#!/bin/bash
yum install -y amazon-efs-utils
mkdir -p /mnt/efs/finance

# 使用访问点挂载
mount -t efs -o tls,accesspoint=fsap-1a2b3c4d fs-1a2b3c4d:/ /mnt/efs/finance

# 添加到/etc/fstab以实现持久挂载
echo "fs-1a2b3c4d:/ /mnt/efs/finance efs _netdev,tls,accesspoint=fsap-1a2b3c4d 0 0" >> /etc/fstab
```

## 最佳实践

1. **访问点隔离**: 为每个业务域/功能创建单独的访问点
2. **严格权限**: 对访问点使用严格的POSIX权限
3. **仅VPC内部访问**: 限制EFS访问仅来自VPC内部
4. **强制Root Squashing**: 在生产环境中始终启用
5. **加密**: 启用传输中和静态数据加密
6. **定期备份**: 启用AWS备份以保护数据

## 故障排除

如果遇到挂载或访问问题:

1. 检查安全组规则是否允许端口2049的流量
2. 验证挂载点与EC2实例处于同一子网或具有网络连接
3. 确认使用正确的挂载命令和参数
4. 检查IAM权限和EFS策略是否正确配置
5. 验证访问点路径和用户权限

## 许可证

这个模块遵循Apache 2.0许可证。

## 贡献

欢迎通过Issue和Pull Request贡献代码和改进建议。

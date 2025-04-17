provider "aws" {
  region = var.region
}

# 获取当前账户ID
data "aws_caller_identity" "current" {}

# 获取可用区
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "nfs_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-nfs-vpc"
    }
  )
}

# 私有子网
resource "aws_subnet" "nfs_private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.nfs_vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-nfs-private-subnet-${count.index + 1}"
    }
  )
}

# 私有路由表 (仅用于VPC内部路由)
resource "aws_route_table" "nfs_private_rt" {
  vpc_id = aws_vpc.nfs_vpc.id

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-nfs-private-rt"
    }
  )
}

# 私有子网关联到私有路由表
resource "aws_route_table_association" "nfs_private_rta" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.nfs_private_subnets[count.index].id
  route_table_id = aws_route_table.nfs_private_rt.id
}

# 使用外部模块创建EFS安全组
module "efs_security_group" {
  source  = var.efs_security_group_module
  version = var.efs_security_group_version

  name        = var.efs_security_group_name != null ? var.efs_security_group_name : "${var.environment}-efs-sg"
  description = "Security group for EFS file system (VPC internal only)"
  vpc_id      = aws_vpc.nfs_vpc.id

  # 允许NFS端口入站流量（仅VPC内部）
  ingress_with_cidr_blocks = [
    {
      from_port   = 2049
      to_port     = 2049
      protocol    = "tcp"
      description = "NFS from within VPC"
      cidr_blocks = aws_vpc.nfs_vpc.cidr_block
    }
  ]

  # 仅允许VPC内部出站流量
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "All traffic within VPC only"
      cidr_blocks = aws_vpc.nfs_vpc.cidr_block
    }
  ]

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-efs-sg"
    }
  )
}

# 调用EFS模块
module "efs" {
  source = "../../modules/efs"

  name               = "${var.environment}-nfs"
  vpc_id             = aws_vpc.nfs_vpc.id
  subnet_ids         = [for subnet in aws_subnet.nfs_private_subnets : subnet.id]
  security_group_id  = module.efs_security_group.security_group_id
  
  # 加密设置
  encrypted          = var.efs_encrypted
  kms_key_id         = var.efs_kms_key_id
  
  # 性能设置
  performance_mode   = var.efs_performance_mode
  throughput_mode    = var.efs_throughput_mode
  provisioned_throughput_in_mibps = var.efs_provisioned_throughput_in_mibps
  
  # 生命周期策略
  lifecycle_policy   = var.efs_lifecycle_policy
  
  # 备份设置
  enable_backup      = var.efs_enable_backup
  
  # 访问点
  access_points      = var.efs_access_points
  
  # 策略设置
  use_default_policy = var.efs_use_default_policy
  file_system_policy = var.efs_file_system_policy
  allowed_cidr_blocks = [aws_vpc.nfs_vpc.cidr_block]
  
  # VPC端点设置 - 不需要连接互联网
  create_vpc_endpoint = false
  
  # 其他设置
  tags               = merge(
    var.tags,
    {
      Environment = var.environment
    }
  )
}

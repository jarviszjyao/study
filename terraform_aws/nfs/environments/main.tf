provider "aws" {
  region = var.region
}

# 获取当前账户ID
data "aws_caller_identity" "current" {}

# 使用指定的VPC ID或创建新的VPC
locals {
  vpc_id = var.vpc_id != null ? var.vpc_id : aws_vpc.nfs_vpc[0].id
  subnet_ids = var.private_subnet_ids != null ? var.private_subnet_ids : [for subnet in aws_subnet.nfs_private_subnets : subnet.id]
}

# 仅在需要时创建VPC
resource "aws_vpc" "nfs_vpc" {
  count = var.vpc_id == null ? 1 : 0

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

# 仅在需要时创建私有子网
resource "aws_subnet" "nfs_private_subnets" {
  count = var.vpc_id == null ? length(var.private_subnet_cidrs) : 0

  vpc_id            = local.vpc_id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available[0].names[count.index % length(data.aws_availability_zones.available[0].names)]

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-nfs-private-subnet-${count.index + 1}"
    }
  )
}

# 仅在创建新VPC时获取可用区信息
data "aws_availability_zones" "available" {
  count = var.vpc_id == null ? 1 : 0
  state = "available"
}

# 仅在需要时创建私有路由表
resource "aws_route_table" "nfs_private_rt" {
  count = var.vpc_id == null ? 1 : 0
  vpc_id = local.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-nfs-private-rt"
    }
  )
}

# 仅在需要时创建路由表关联
resource "aws_route_table_association" "nfs_private_rta" {
  count = var.vpc_id == null ? length(var.private_subnet_cidrs) : 0

  subnet_id      = aws_subnet.nfs_private_subnets[count.index].id
  route_table_id = aws_route_table.nfs_private_rt[0].id
}

# 创建安全组 - 使用指定的基础安全组模块
module "security_group" {
  count = length(var.sg_egress_rules) > 0 || length(var.sg_ingress_rules) > 0 ? 1 : 0
  
  source = "git::"
  
  description = var.sg_description
  vpc_id = local.vpc_id
  sg_ingress_rules = var.sg_ingress_rules
  sg_egress_rules = var.sg_egress_rules
  region = var.region
  tags = var.sg_tags
}

# 调用EFS模块
module "efs" {
  source = "../../modules/efs"

  name = "${var.environment}-nfs"
  vpc_id = local.vpc_id
  subnet_ids = local.subnet_ids
  security_group_id = length(var.sg_egress_rules) > 0 || length(var.sg_ingress_rules) > 0 ? module.security_group[0].sg_id : null
  
  # 加密设置
  encrypted = var.efs_encrypted
  kms_key_id = var.efs_kms_key_id
  
  # 性能设置
  performance_mode = var.efs_performance_mode
  throughput_mode = var.efs_throughput_mode
  provisioned_throughput_in_mibps = var.efs_provisioned_throughput_in_mibps
  
  # 生命周期策略
  lifecycle_policy = var.efs_lifecycle_policy
  
  # 备份设置
  enable_backup = var.efs_enable_backup
  
  # 访问点
  access_points = var.efs_access_points
  
  # Root Squashing - 安全要求
  enforce_root_squashing = var.efs_enforce_root_squashing
  
  # 策略设置
  use_default_policy = var.efs_use_default_policy
  file_system_policy = var.efs_file_system_policy
  allowed_cidr_blocks = var.efs_allowed_cidr_blocks
  
  # 引用现有VPC端点
  existing_vpc_endpoint_id = var.existing_vpc_endpoint_id
  
  # 区域
  region = var.region
  
  # 其他设置
  tags = merge(
    var.tags,
    {
      Environment = var.environment
    }
  )
}

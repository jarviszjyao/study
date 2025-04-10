terraform {
  backend "s3" {}
}

provider "aws" {
  region = var.region
}

locals {
  name = "${var.environment}-${var.project}"
  
  # 标准化标签
  common_tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
    ManagedBy   = "terraform"
  }
}

# 验证 VPC 存在
data "aws_vpc" "selected" {
  id = var.vpc_id
}

# 获取所有路由子网
data "aws_subnets" "routable" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "tag:Type"
    values = ["Routable"]
  }
}

# 获取所有私有子网
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "tag:Type"
    values = ["Private"]
  }
}

# 验证子网是否存在
resource "null_resource" "subnet_validation" {
  lifecycle {
    precondition {
      condition     = length(data.aws_subnets.routable.ids) > 0
      error_message = "No routable subnets found with tag:Type=Routable in the specified VPC."
    }
    
    precondition {
      condition     = length(data.aws_subnets.private.ids) > 0
      error_message = "No private subnets found with tag:Type=Private in the specified VPC."
    }
  }
}

# 获取所有路由子网的详细信息
data "aws_subnet" "routable" {
  for_each = toset(data.aws_subnets.routable.ids)
  id       = each.value
}

# 获取所有私有子网的详细信息
data "aws_subnet" "private" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
}

# 整理子网信息，确保按 AZ 分组
locals {
  # 获取可用区列表
  azs = distinct([for s in data.aws_subnet.routable : s.availability_zone])
  
  # 按可用区组织子网 ID，确保每个 AZ 最多选择一个子网
  routable_subnet_by_az = {
    for az in local.azs :
      az => [for id, s in data.aws_subnet.routable : s.id if s.availability_zone == az]
  }
  
  private_subnet_by_az = {
    for az in local.azs :
      az => [for id, s in data.aws_subnet.private : s.id if s.availability_zone == az]
  }
  
  # 确保每个 AZ 选取第一个子网 ID，避免索引越界
  routable_subnet_ids = [
    for az in local.azs : 
      length(lookup(local.routable_subnet_by_az, az, [])) > 0 
        ? local.routable_subnet_by_az[az][0] 
        : null
  ]
  
  private_subnet_ids = [
    for az in local.azs : 
      length(lookup(local.private_subnet_by_az, az, [])) > 0 
        ? local.private_subnet_by_az[az][0] 
        : null
  ]
  
  # 移除空值
  final_routable_subnet_ids = compact(local.routable_subnet_ids)
  final_private_subnet_ids = compact(local.private_subnet_ids)
  
  # 验证现有路由表参数
  using_existing_route_tables = !var.create_private_route_tables
  route_table_validation_needed = local.using_existing_route_tables && length(var.existing_private_route_table_ids) > 0
}

# 验证最终子网列表
resource "null_resource" "final_validation" {
  lifecycle {
    precondition {
      condition     = length(local.final_routable_subnet_ids) > 0
      error_message = "Could not map routable subnets to availability zones."
    }
    
    precondition {
      condition     = length(local.final_private_subnet_ids) > 0
      error_message = "Could not map private subnets to availability zones."
    }
    
    precondition {
      condition     = length(local.final_routable_subnet_ids) == length(local.azs)
      error_message = "Not all availability zones have a corresponding routable subnet."
    }
    
    precondition {
      condition     = length(local.final_private_subnet_ids) == length(local.azs)
      error_message = "Not all availability zones have a corresponding private subnet."
    }
    
    # 验证现有路由表 IDs
    precondition {
      condition     = !local.route_table_validation_needed || length(var.existing_private_route_table_ids) == length(local.final_private_subnet_ids)
      error_message = "When using existing route tables, you must provide the same number of route table IDs as private subnets."
    }
  }
}

# 获取已存在的路由表信息 (当使用现有路由表时)
data "aws_route_table" "existing" {
  count = local.route_table_validation_needed ? length(var.existing_private_route_table_ids) : 0
  id    = element(var.existing_private_route_table_ids, count.index)
}

module "nat_gateway" {
  source = "../modules/nat_gateway"

  name                 = local.name
  vpc_id               = var.vpc_id
  azs                  = local.azs
  routable_subnet_ids  = local.final_routable_subnet_ids
  private_subnet_ids   = local.final_private_subnet_ids
  single_nat_gateway   = var.single_nat_gateway
  destination_cidr_block = var.destination_cidr_block
  
  # 传递新增的路由表参数
  additional_route_cidr_blocks  = var.additional_route_cidr_blocks
  create_private_route_tables   = var.create_private_route_tables
  existing_private_route_table_ids = var.existing_private_route_table_ids
  
  # 可选：为 NAT Gateway 添加依赖资源
  nat_gateway_depends_on = []
  
  tags = local.common_tags
}

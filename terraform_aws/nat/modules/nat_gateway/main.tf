terraform {
  required_version = ">= 0.13.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
  }
}

locals {
  nat_gateway_count = var.single_nat_gateway ? 1 : length(var.routable_subnet_ids)
  
  # 确保 AZ 与子网数量匹配
  az_count = length(var.azs)
  routable_subnet_count = length(var.routable_subnet_ids)
  private_subnet_count = length(var.private_subnet_ids)
  
  # 标准化标签
  default_tags = {
    Name        = var.name
    Terraform   = "true"
    Module      = "nat-gateway"
  }
  
  all_tags = merge(local.default_tags, var.tags)

  # 处理路由表 ID - 使用现有的或创建新的
  private_route_table_ids = var.create_private_route_tables ? aws_route_table.private[*].id : var.existing_private_route_table_ids

  # 合并主要 CIDR 和额外 CIDR 列表
  all_destination_cidrs = concat([var.destination_cidr_block], var.additional_route_cidr_blocks)
}

# 前置条件检查
resource "null_resource" "preconditions" {
  # 确保 AZ 数量与子网数量匹配
  lifecycle {
    precondition {
      condition     = local.az_count >= local.routable_subnet_count
      error_message = "The number of availability zones must be greater than or equal to the number of routable subnets."
    }
    
    precondition {
      condition     = local.az_count >= local.private_subnet_count
      error_message = "The number of availability zones must be greater than or equal to the number of private subnets."
    }
    
    precondition {
      condition     = !var.single_nat_gateway || local.routable_subnet_count > 0
      error_message = "At least one routable subnet must be provided."
    }

    # 验证现有路由表配置
    precondition {
      condition     = var.create_private_route_tables || length(var.existing_private_route_table_ids) == length(var.private_subnet_ids)
      error_message = "When using existing route tables, you must provide one route table ID for each private subnet."
    }
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  count  = local.nat_gateway_count
  domain = "vpc"

  tags = merge(
    local.all_tags,
    {
      Name = format(
        "${var.name}-nat-eip-%s",
        element(var.azs, count.index),
      )
    }
  )
  
  lifecycle {
    # 防止意外删除 EIP
    prevent_destroy = false # 生产环境可设为 true
  }
}

# NAT Gateway
resource "aws_nat_gateway" "this" {
  count         = local.nat_gateway_count
  allocation_id = element(aws_eip.nat.*.id, count.index)
  subnet_id     = element(var.routable_subnet_ids, count.index)

  tags = merge(
    local.all_tags,
    {
      Name = format(
        "${var.name}-natgw-%s",
        element(var.azs, count.index),
      )
    }
  )

  # 明确依赖 EIP 和传入的依赖资源
  depends_on = concat([aws_eip.nat[count.index]], var.nat_gateway_depends_on)
  
  lifecycle {
    # 防止意外删除 NAT Gateway
    prevent_destroy = false # 生产环境可设为 true
  }
  
  # 添加超时设置
  timeouts {
    create = "10m"
    delete = "10m"
    update = "10m"
  }
}

# Route table for private subnets (只在需要创建新路由表时创建)
resource "aws_route_table" "private" {
  count  = var.create_private_route_tables ? length(var.private_subnet_ids) : 0
  vpc_id = var.vpc_id

  tags = merge(
    local.all_tags,
    {
      Name = format(
        "${var.name}-private-rt-%s",
        element(var.azs, count.index),
      )
      Type = "private"
    }
  )
  
  lifecycle {
    # 创建新资源再删除旧资源，减少停机时间
    create_before_destroy = true
  }
}

# 主要路由 - 针对主要目标 CIDR
resource "aws_route" "private_nat_gateway" {
  count = length(var.private_subnet_ids)

  route_table_id         = element(local.private_route_table_ids, count.index)
  destination_cidr_block = var.destination_cidr_block
  nat_gateway_id         = element(
    aws_nat_gateway.this.*.id, 
    var.single_nat_gateway ? 0 : count.index
  )

  timeouts {
    create = "5m"
    delete = "5m"
    update = "5m"
  }
  
  depends_on = [aws_route_table.private, aws_nat_gateway.this]
}

# 添加额外 CIDR 路由 (如果提供)
resource "aws_route" "additional_cidr_routes" {
  # 为每个私有子网的每个额外 CIDR 创建路由
  for_each = {
    for pair in setproduct(range(length(var.private_subnet_ids)), range(length(var.additional_route_cidr_blocks))) :
    "${pair[0]}-${pair[1]}" => {
      route_table_index = pair[0]
      cidr_index        = pair[1]
    }
  }

  route_table_id         = element(local.private_route_table_ids, each.value.route_table_index)
  destination_cidr_block = element(var.additional_route_cidr_blocks, each.value.cidr_index)
  nat_gateway_id         = element(
    aws_nat_gateway.this.*.id,
    var.single_nat_gateway ? 0 : each.value.route_table_index
  )

  timeouts {
    create = "5m"
    delete = "5m"
    update = "5m"
  }

  depends_on = [aws_route_table.private, aws_nat_gateway.this]
}

# Associate route tables with private subnets (只在创建新路由表时关联)
resource "aws_route_table_association" "private" {
  count = var.create_private_route_tables ? length(var.private_subnet_ids) : 0

  subnet_id      = element(var.private_subnet_ids, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
  
  depends_on = [aws_route_table.private]
  
  lifecycle {
    # 创建新资源再删除旧资源，减少停机时间
    create_before_destroy = true
  }
}

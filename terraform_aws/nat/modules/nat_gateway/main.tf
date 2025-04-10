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
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  count  = local.nat_gateway_count
  domain = "vpc"

  tags = merge(
    {
      Name = format(
        "${var.name}-nat-eip-%s",
        element(var.azs, count.index),
      )
    },
    var.tags
  )
}

# NAT Gateway
resource "aws_nat_gateway" "this" {
  count         = local.nat_gateway_count
  allocation_id = element(aws_eip.nat.*.id, count.index)
  subnet_id     = element(var.routable_subnet_ids, count.index)

  tags = merge(
    {
      Name = format(
        "${var.name}-natgw-%s",
        element(var.azs, count.index),
      )
    },
    var.tags
  )

  depends_on = [var.nat_gateway_depends_on]
}

# Route table for private subnets
resource "aws_route_table" "private" {
  count  = length(var.private_subnet_ids)
  vpc_id = var.vpc_id

  tags = merge(
    {
      Name = format(
        "${var.name}-private-rt-%s",
        element(var.azs, count.index),
      )
    },
    var.tags
  )
}

# Route to NAT Gateway for private subnets
resource "aws_route" "private_nat_gateway" {
  count = length(var.private_subnet_ids)

  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = var.destination_cidr_block
  nat_gateway_id         = element(
    aws_nat_gateway.this.*.id, 
    var.single_nat_gateway ? 0 : count.index
  )

  timeouts {
    create = "5m"
  }
}

# Associate route tables with private subnets
resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_ids)

  subnet_id      = element(var.private_subnet_ids, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

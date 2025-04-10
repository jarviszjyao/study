terraform {
  backend "s3" {}
}

provider "aws" {
  region = var.region
}

locals {
  name = "${var.environment}-${var.project}"
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

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

data "aws_subnet" "routable" {
  for_each = toset(data.aws_subnets.routable.ids)
  id       = each.value
}

data "aws_subnet" "private" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
}

locals {
  azs                = distinct([for s in data.aws_subnet.routable : s.availability_zone])
  routable_subnet_ids = [for az in local.azs : [for s in data.aws_subnet.routable : s.id if s.availability_zone == az][0]]
  private_subnet_ids = [for az in local.azs : [for s in data.aws_subnet.private : s.id if s.availability_zone == az][0]]
}

module "nat_gateway" {
  source = "../modules/nat_gateway"

  name                 = local.name
  vpc_id               = var.vpc_id
  azs                  = local.azs
  routable_subnet_ids  = local.routable_subnet_ids
  private_subnet_ids   = local.private_subnet_ids
  single_nat_gateway   = var.single_nat_gateway
  destination_cidr_block = var.destination_cidr_block
  
  tags = {
    Environment = var.environment
    Project     = var.project
    Terraform   = "true"
  }
}

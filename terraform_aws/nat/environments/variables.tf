variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "vpc_id" {
  description = "VPC ID where NAT Gateway and route tables will be created"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "single_nat_gateway" {
  description = "Should be true if you want to provision a single NAT Gateway for all private subnets"
  type        = bool
  default     = false
}

variable "destination_cidr_block" {
  description = "Destination CIDR block for NAT Gateway routes"
  type        = string
  default     = "0.0.0.0/0"
}

variable "additional_route_cidr_blocks" {
  description = "Additional CIDR blocks to route through the NAT Gateway"
  type        = list(string)
  default     = []
}

variable "create_private_route_tables" {
  description = "Whether to create new route tables for private subnets"
  type        = bool
  default     = true
}

variable "existing_private_route_table_ids" {
  description = "List of existing private route table IDs (only used when create_private_route_tables is false)"
  type        = list(string)
  default     = []
}

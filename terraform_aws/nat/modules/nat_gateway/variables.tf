variable "name" {
  description = "Name prefix for resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where NAT Gateway and route tables will be created"
  type        = string
}

variable "azs" {
  description = "A list of availability zones to deploy resources in"
  type        = list(string)
}

variable "routable_subnet_ids" {
  description = "List of routable subnet IDs where NAT Gateway will be placed"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs that will use the NAT Gateway"
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "Should be true if you want to provision a single NAT Gateway for all private subnets"
  type        = bool
  default     = false
}

variable "destination_cidr_block" {
  description = "Destination CIDR block for NAT Gateway routes (default 0.0.0.0/0)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "nat_gateway_depends_on" {
  description = "Resources that the NAT Gateway depends on"
  type        = list(any)
  default     = []
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

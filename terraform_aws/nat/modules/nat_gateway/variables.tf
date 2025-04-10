variable "name" {
  description = "Name prefix for resources created by this module"
  type        = string

  validation {
    condition     = length(var.name) > 0
    error_message = "The name value must not be empty."
  }
}

variable "vpc_id" {
  description = "VPC ID where NAT Gateway and route tables will be created"
  type        = string

  validation {
    condition     = can(regex("^vpc-", var.vpc_id))
    error_message = "The vpc_id value must be a valid VPC ID, starting with 'vpc-'."
  }
}

variable "azs" {
  description = "A list of availability zones to deploy resources in. These should match the AZs where your subnets are located."
  type        = list(string)

  validation {
    condition     = length(var.azs) > 0
    error_message = "At least one availability zone must be specified."
  }
}

variable "routable_subnet_ids" {
  description = "List of routable subnet IDs where NAT Gateway will be placed. These should be subnets with routes to the internet/Direct Connect."
  type        = list(string)

  validation {
    condition     = length(var.routable_subnet_ids) > 0
    error_message = "At least one routable subnet ID must be specified."
  }
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs that will use the NAT Gateway. These should be subnets where your private instances are located."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) > 0
    error_message = "At least one private subnet ID must be specified."
  }
}

variable "single_nat_gateway" {
  description = "Should be true if you want to provision a single NAT Gateway for all private subnets (less expensive but introduces a single point of failure)"
  type        = bool
  default     = false
}

variable "destination_cidr_block" {
  description = "Destination CIDR block for NAT Gateway routes (default 0.0.0.0/0 for internet access, or use your corporate network CIDR for internal routing)"
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = can(cidrnetmask(var.destination_cidr_block))
    error_message = "The destination_cidr_block value must be a valid CIDR block."
  }
}

variable "additional_route_cidr_blocks" {
  description = "Additional CIDR blocks to route through the NAT Gateway (optional)"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.additional_route_cidr_blocks : can(cidrnetmask(cidr))
    ])
    error_message = "All values in additional_route_cidr_blocks must be valid CIDR blocks."
  }
}

variable "create_private_route_tables" {
  description = "Whether to create new route tables for private subnets (set to false if you want to use existing route tables)"
  type        = bool
  default     = true
}

variable "existing_private_route_table_ids" {
  description = "List of existing private route table IDs to use instead of creating new ones (only used when create_private_route_tables is false)"
  type        = list(string)
  default     = []
}

variable "nat_gateway_depends_on" {
  description = "Resources that the NAT Gateway depends on (e.g., Internet Gateway for public routing)"
  type        = list(any)
  default     = []
}

variable "tags" {
  description = "A map of tags to add to all resources created by this module"
  type        = map(string)
  default     = {}
}

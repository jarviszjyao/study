variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g. dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_id" {
  description = "ID of an existing VPC where resources will be deployed"
  type        = string
  default     = null
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "private_subnet_ids" {
  description = "List of existing private subnet IDs to use for EFS mount targets"
  type        = list(string)
  default     = null
}

# Security Group Configuration
variable "sg_description" {
  description = "Description for the EFS security group"
  type        = string
  default     = "Security group for EFS file system (VPC internal only)"
}

variable "sg_ingress_rules" {
  description = "List of ingress rules for the EFS security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = optional(list(string))
    security_groups = optional(list(string))
    description = optional(string)
  }))
  default = []
}

variable "sg_egress_rules" {
  description = "List of egress rules for the EFS security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = optional(list(string))
    security_groups = optional(list(string))
    description = optional(string)
  }))
  default = []
}

variable "sg_tags" {
  description = "Tags to attach to the security group"
  type        = map(string)
  default     = {}
}

# EFS Configuration
variable "efs_encrypted" {
  description = "Whether to enable encryption for the EFS file system"
  type        = bool
  default     = true
}

variable "efs_kms_key_id" {
  description = "The ARN of the KMS key to use for EFS encryption"
  type        = string
  default     = null
}

variable "efs_performance_mode" {
  description = "The performance mode for the EFS file system (generalPurpose or maxIO)"
  type        = string
  default     = "generalPurpose"
}

variable "efs_throughput_mode" {
  description = "The throughput mode for the EFS file system (bursting, provisioned, or elastic)"
  type        = string
  default     = "bursting"
}

variable "efs_provisioned_throughput_in_mibps" {
  description = "The throughput, in MiB/s, to provision for the file system"
  type        = number
  default     = null
}

variable "efs_lifecycle_policy" {
  description = "Map of lifecycle policies to apply to the file system"
  type        = map(string)
  default     = {
    "transition_to_ia" = "AFTER_30_DAYS"
  }
}

variable "efs_enable_backup" {
  description = "Whether to enable AWS Backup for the EFS file system"
  type        = bool
  default     = true
}

variable "efs_allowed_cidr_blocks" {
  description = "List of CIDR blocks to allow access to the EFS file system (should be within VPC CIDR)"
  type        = list(string)
  default     = []
}

variable "efs_access_points" {
  description = "Map of access points to create for the EFS file system. IMPORTANT: Each Business Domain/Function MUST use a unique access point following the principle of least privilege."
  type = map(object({
    posix_user = object({
      uid            = number
      gid            = number
      secondary_gids = optional(list(number), null)
    })
    root_directory = object({
      path        = string
      creation_info = optional(object({
        owner_uid   = number
        owner_gid   = number
        permissions = string
      }), null)
    })
    tags        = optional(map(string), {})
  }))
  default     = {}
}

variable "efs_enforce_root_squashing" {
  description = "Whether to enforce root squashing for the EFS file system. MUST be set to true for production environments."
  type        = bool
  default     = true
}

variable "efs_use_default_policy" {
  description = "Whether to use the default policy from policies/default_policy.json.tpl"
  type        = bool
  default     = true
}

variable "efs_file_system_policy" {
  description = "A JSON formatted string containing custom policy for the EFS file system"
  type        = string
  default     = null
}

variable "existing_vpc_endpoint_id" {
  description = "ID of existing VPC endpoint for EFS to reference"
  type        = string
  default     = null
}

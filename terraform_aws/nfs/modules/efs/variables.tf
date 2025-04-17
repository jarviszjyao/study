variable "name" {
  description = "Name to be used on all resources as identifier"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where to create the EFS resources"
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs to create mount targets in"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID of the security group to use for EFS mount targets"
  type        = string
  default     = null
}

variable "allowed_cidr_blocks" {
  description = "A list of CIDR blocks to allow access from (used in default policy)"
  type        = list(string)
  default     = []
}

variable "encrypted" {
  description = "If true, the file system will be encrypted"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "The ARN for the KMS encryption key. If not specified, the default KMS key for EFS will be used"
  type        = string
  default     = null
}

variable "performance_mode" {
  description = "The file system performance mode. Can be either 'generalPurpose' or 'maxIO'"
  type        = string
  default     = "generalPurpose"
  validation {
    condition     = contains(["generalPurpose", "maxIO"], var.performance_mode)
    error_message = "Valid values are generalPurpose and maxIO."
  }
}

variable "throughput_mode" {
  description = "Throughput mode for the file system. Can be 'bursting', 'provisioned', or 'elastic'"
  type        = string
  default     = "bursting"
  validation {
    condition     = contains(["bursting", "provisioned", "elastic"], var.throughput_mode)
    error_message = "Valid values are bursting, provisioned, and elastic."
  }
}

variable "provisioned_throughput_in_mibps" {
  description = "The throughput, measured in MiB/s, that you want to provision for the file system. Only applicable with throughput_mode set to provisioned"
  type        = number
  default     = null
}

variable "enable_backup" {
  description = "If true, AWS Backup is enabled for the file system"
  type        = bool
  default     = true
}

variable "lifecycle_policy" {
  description = "A map of lifecycle policies to apply to the file system"
  type        = map(string)
  default     = {}
}

variable "access_points" {
  description = "A map of access point definitions to create"
  type = map(object({
    posix_user = object({
      uid         = number
      gid         = number
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

variable "file_system_policy" {
  description = "A JSON formatted string containing custom policy for the EFS file system"
  type        = string
  default     = null
}

variable "use_default_policy" {
  description = "Whether to use the default policy from policies/default_policy.json"
  type        = bool
  default     = false
}

variable "bypass_policy_lockout_safety_check" {
  description = "Whether to bypass the aws_efs_file_system_policy lockout safety check"
  type        = bool
  default     = false
}

variable "create_vpc_endpoint" {
  description = "If true, a VPC endpoint for EFS will be created"
  type        = bool
  default     = true
}

variable "vpc_endpoint_subnet_ids" {
  description = "A list of subnet IDs for the VPC endpoint. If not specified, subnet_ids will be used"
  type        = list(string)
  default     = null
}

variable "vpc_endpoint_security_group_ids" {
  description = "A list of security group IDs to use for the VPC endpoint. If not specified, a new security group will be created"
  type        = list(string)
  default     = null
}

variable "vpc_endpoint_policy" {
  description = "A policy to apply to the VPC endpoint"
  type        = string
  default     = null
}

variable "vpc_endpoint_private_dns_enabled" {
  description = "Whether or not to enable private DNS for the VPC endpoint"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "file_system_tags" {
  description = "Additional tags for the file system"
  type        = map(string)
  default     = {}
}

variable "vpc_endpoint_tags" {
  description = "Additional tags for the VPC endpoint"
  type        = map(string)
  default     = {}
}

variable "access_point_tags" {
  description = "Additional tags for all access points"
  type        = map(string)
  default     = {}
}

locals {
  name                       = var.name
  vpc_endpoint_subnet_ids    = var.vpc_endpoint_subnet_ids != null ? var.vpc_endpoint_subnet_ids : var.subnet_ids
  vpc_endpoint_security_group_ids = var.vpc_endpoint_security_group_ids != null ? var.vpc_endpoint_security_group_ids : var.security_group_id != null ? [var.security_group_id] : []
  all_mount_target_ips       = flatten([for mt in aws_efs_mount_target.this : mt.ip_address])
  
  # Create a JSON array of allowed CIDRs and mount target IPs for use in the policy template
  allowed_ips_json = jsonencode(concat(var.allowed_cidr_blocks, local.all_mount_target_ips))
}

# EFS File System
resource "aws_efs_file_system" "this" {
  creation_token                  = local.name
  encrypted                       = var.encrypted
  kms_key_id                      = var.kms_key_id
  performance_mode                = var.performance_mode
  throughput_mode                 = var.throughput_mode
  provisioned_throughput_in_mibps = var.throughput_mode == "provisioned" ? var.provisioned_throughput_in_mibps : null

  dynamic "lifecycle_policy" {
    for_each = var.lifecycle_policy
    content {
      transition_to_ia                    = lookup(lifecycle_policy.value, "transition_to_ia", null)
      transition_to_primary_storage_class = lookup(lifecycle_policy.value, "transition_to_primary_storage_class", null)
    }
  }

  tags = merge(
    var.tags,
    var.file_system_tags,
    {
      Name = local.name
    },
  )
}

# EFS Mount Targets
resource "aws_efs_mount_target" "this" {
  for_each = toset(var.subnet_ids)

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = each.value
  security_groups = var.security_group_id != null ? [var.security_group_id] : []
}

# EFS Access Points
resource "aws_efs_access_point" "this" {
  for_each = var.access_points

  file_system_id = aws_efs_file_system.this.id

  dynamic "posix_user" {
    for_each = each.value.posix_user != null ? [each.value.posix_user] : []
    content {
      uid            = posix_user.value.uid
      gid            = posix_user.value.gid
      secondary_gids = posix_user.value.secondary_gids
    }
  }

  root_directory {
    path = each.value.root_directory.path

    dynamic "creation_info" {
      for_each = lookup(each.value.root_directory, "creation_info", null) != null ? [each.value.root_directory.creation_info] : []
      content {
        owner_uid   = creation_info.value.owner_uid
        owner_gid   = creation_info.value.owner_gid
        permissions = creation_info.value.permissions
      }
    }
  }

  tags = merge(
    var.tags,
    var.access_point_tags,
    lookup(each.value, "tags", {}),
    {
      Name = "${local.name}-${each.key}"
    },
  )
}

# AWS Backup
resource "aws_efs_backup_policy" "this" {
  file_system_id = aws_efs_file_system.this.id

  backup_policy {
    status = var.enable_backup ? "ENABLED" : "DISABLED"
  }
}

# VPC Endpoint for EFS
resource "aws_vpc_endpoint" "efs" {
  count               = var.create_vpc_endpoint ? 1 : 0
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.elasticfilesystem"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = local.vpc_endpoint_subnet_ids
  security_group_ids  = local.vpc_endpoint_security_group_ids
  policy              = var.vpc_endpoint_policy
  private_dns_enabled = var.vpc_endpoint_private_dns_enabled

  tags = merge(
    var.tags,
    var.vpc_endpoint_tags,
    {
      Name = "${local.name}-efs-endpoint"
    },
  )
}

# Generate default policy from template
data "template_file" "default_policy" {
  count = var.use_default_policy ? 1 : 0
  
  template = file("${path.module}/policies/default_policy.json.tpl")
  vars = {
    file_system_arn = aws_efs_file_system.this.arn
    allowed_ips     = local.allowed_ips_json
  }
}

# EFS File System Policy
resource "aws_efs_file_system_policy" "this" {
  count = var.file_system_policy != null || var.use_default_policy ? 1 : 0
  
  file_system_id = aws_efs_file_system.this.id
  policy         = var.file_system_policy != null ? var.file_system_policy : data.template_file.default_policy[0].rendered
  bypass_policy_lockout_safety_check = var.bypass_policy_lockout_safety_check
}

# Current region data
data "aws_region" "current" {}

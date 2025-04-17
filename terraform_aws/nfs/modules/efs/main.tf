locals {
  name                       = var.name
  all_mount_target_ips       = flatten([for mt in aws_efs_mount_target.this : mt.ip_address])
  
  # Create a JSON array of allowed CIDRs and mount target IPs for use in the policy template
  allowed_ips_json = jsonencode(concat(var.allowed_cidr_blocks, local.all_mount_target_ips))

  # Root squashing policy statement for file system policy
  root_squashing_statement = var.enforce_root_squashing ? {
    sid       = "EnforceRootSquashing"
    effect    = "Deny"
    actions   = ["elasticfilesystem:ClientRootAccess"]
    resources = [aws_efs_file_system.this.arn]
    principals = {
      type        = "*"
      identifiers = ["*"]
    }
  } : null
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

# EFS Access Points - Unique per Business Domain/Function with proper isolation
resource "aws_efs_access_point" "this" {
  for_each = var.access_points

  file_system_id = aws_efs_file_system.this.id

  # Enforcing POSIX user settings for proper permission isolation
  dynamic "posix_user" {
    for_each = each.value.posix_user != null ? [each.value.posix_user] : []
    content {
      uid            = posix_user.value.uid
      gid            = posix_user.value.gid
      secondary_gids = posix_user.value.secondary_gids
    }
  }

  # Configuring isolated root directory for each access point
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

  # Add dependency on mount targets to ensure they're created first
  depends_on = [aws_efs_mount_target.this]
}

# AWS Backup
resource "aws_efs_backup_policy" "this" {
  file_system_id = aws_efs_file_system.this.id

  backup_policy {
    status = var.enable_backup ? "ENABLED" : "DISABLED"
  }
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

# Reference existing VPC endpoint data
data "aws_vpc_endpoint" "efs" {
  count = var.existing_vpc_endpoint_id != null ? 1 : 0
  id    = var.existing_vpc_endpoint_id
}

# Generate root squashing policy JSON
data "aws_iam_policy_document" "root_squashing" {
  count = var.enforce_root_squashing ? 1 : 0

  statement {
    sid    = "EnforceRootSquashing"
    effect = "Deny"
    actions = [
      "elasticfilesystem:ClientRootAccess"
    ]
    resources = [aws_efs_file_system.this.arn]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

# Combine custom policy with root squashing policy if needed
locals {
  final_policy = var.file_system_policy != null ? (
    var.enforce_root_squashing ? (
      # Combine user policy with root squashing
      jsonencode(
        jsondecode(
          var.file_system_policy
        ).Statement + jsondecode(data.aws_iam_policy_document.root_squashing[0].json).Statement
      )
    ) : var.file_system_policy
  ) : (
    var.use_default_policy ? (
      var.enforce_root_squashing ? (
        # Combine default policy with root squashing
        jsonencode(
          jsondecode(
            data.template_file.default_policy[0].rendered
          ).Statement + jsondecode(data.aws_iam_policy_document.root_squashing[0].json).Statement
        )
      ) : data.template_file.default_policy[0].rendered
    ) : (
      var.enforce_root_squashing ? data.aws_iam_policy_document.root_squashing[0].json : null
    )
  )
}

# EFS File System Policy
resource "aws_efs_file_system_policy" "this" {
  count = local.final_policy != null ? 1 : 0
  
  file_system_id = aws_efs_file_system.this.id
  policy         = local.final_policy
  bypass_policy_lockout_safety_check = var.bypass_policy_lockout_safety_check
}

# Current region data
data "aws_region" "current" {}

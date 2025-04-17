region      = "us-east-1"
environment = "dev"
tags        = {
  Project     = "NFS-Storage"
  ManagedBy   = "Terraform"
  Owner       = "DevOps"
}

# VPC Configuration
vpc_cidr             = "10.0.0.0/16"
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

# Security Group Configuration
efs_security_group_module  = "terraform-aws-modules/security-group/aws"
efs_security_group_version = "4.17.1"
efs_security_group_name    = "efs-sg"

# EFS Configuration
efs_encrypted        = true
efs_performance_mode = "generalPurpose"
efs_throughput_mode  = "bursting"
efs_lifecycle_policy = {
  "transition_to_ia" = "AFTER_30_DAYS"
}
efs_enable_backup    = true
efs_allowed_cidr_blocks = ["10.0.0.0/16"]  # 只允许VPC内部访问

# 创建示例访问点
efs_access_points    = {
  app1 = {
    posix_user = {
      uid = 1000
      gid = 1000
    }
    root_directory = {
      path = "/app1"
      creation_info = {
        owner_uid   = 1000
        owner_gid   = 1000
        permissions = "755"
      }
    }
    tags = {
      Name = "app1-access-point"
    }
  },
  app2 = {
    posix_user = {
      uid = 1001
      gid = 1001
    }
    root_directory = {
      path = "/app2"
      creation_info = {
        owner_uid   = 1001
        owner_gid   = 1001
        permissions = "755"
      }
    }
    tags = {
      Name = "app2-access-point"
    }
  }
}

# 使用默认策略
efs_use_default_policy = true

# VPC端点设置 - 不需要连接互联网
efs_create_vpc_endpoint = false

region      = "us-east-1"
environment = "dev"
tags        = {
  Project     = "NFS-Storage"
  ManagedBy   = "Terraform"
  Owner       = "DevOps"
}

# VPC Configuration
vpc_id               = "vpc-12345678" # 使用现有VPC的ID
private_subnet_ids   = ["subnet-1a2b3c4d", "subnet-5e6f7g8h"] # 使用现有子网的ID

# 安全组规则配置
sg_description = "Security group for EFS in VPC internal network"
sg_ingress_rules = [
  {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "NFS from within VPC"
  }
]
sg_egress_rules = [
  {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
    description = "All traffic within VPC only"
  }
]
sg_tags = {
  Name = "efs-security-group"
}

# 现有VPC Endpoint配置
existing_vpc_endpoint_id = "vpce-12345678" # 使用现有VPC endpoint的ID

# EFS Configuration
efs_encrypted        = true
efs_performance_mode = "generalPurpose"
efs_throughput_mode  = "bursting"
efs_lifecycle_policy = {
  "transition_to_ia" = "AFTER_30_DAYS"
}
efs_enable_backup    = true
efs_allowed_cidr_blocks = ["10.0.0.0/16"]  # 只允许VPC内部访问

# 强制启用root squashing（符合安全要求）
efs_enforce_root_squashing = true  # 生产环境必须设置为true

# 为不同业务域创建唯一访问点（满足最小权限原则）
efs_access_points    = {
  # 财务部门访问点
  finance = {
    posix_user = {
      uid = 1000
      gid = 1000
    }
    root_directory = {
      path = "/finance"
      creation_info = {
        owner_uid   = 1000
        owner_gid   = 1000
        permissions = "750"  # 严格权限控制
      }
    }
    tags = {
      Name = "finance-access-point"
      BusinessDomain = "Finance"
    }
  },
  # 营销部门访问点
  marketing = {
    posix_user = {
      uid = 1001
      gid = 1001
    }
    root_directory = {
      path = "/marketing"
      creation_info = {
        owner_uid   = 1001
        owner_gid   = 1001
        permissions = "750"  # 严格权限控制
      }
    }
    tags = {
      Name = "marketing-access-point"
      BusinessDomain = "Marketing"
    }
  },
  # IT部门访问点
  it = {
    posix_user = {
      uid = 1002
      gid = 1002
    }
    root_directory = {
      path = "/it"
      creation_info = {
        owner_uid   = 1002
        owner_gid   = 1002
        permissions = "750"  # 严格权限控制
      }
    }
    tags = {
      Name = "it-access-point"
      BusinessDomain = "IT"
    }
  }
}

# 使用默认策略
efs_use_default_policy = true

# VPC端点设置 - 不需要连接互联网
efs_create_vpc_endpoint = false

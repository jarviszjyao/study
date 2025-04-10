# AWS 区域配置
region = "eu-west-1"

# VPC 配置 - 在应用前必须修改此值为实际的 VPC ID
vpc_id = "vpc-0123456789abcdef0"  # 示例值，必须更新为实际 VPC ID

# 环境和项目标识
environment = "prod"
project     = "internal-network"

# NAT Gateway 配置
# true 代表只部署单个 NAT Gateway (成本低但有单点故障风险)
# false 代表每个可用区部署一个 NAT Gateway (成本高但提高可用性)
single_nat_gateway = false  

# 目标 CIDR 范围 - 如果通过 NAT Gateway 访问内网，应设置为内网 CIDR
# 如需访问互联网，应设置为 "0.0.0.0/0"
destination_cidr_block = "10.0.0.0/8"  # 企业内网 CIDR 范围，按需调整

# 额外的路由 CIDR (可选) - 如果需要通过 NAT Gateway 路由额外的 CIDR 块
# 例如，可能需要同时路由到多个内网 CIDR 范围
additional_route_cidr_blocks = [
  # "172.16.0.0/12",  # 示例值，取消注释并按需调整
  # "192.168.0.0/16"  # 示例值，取消注释并按需调整
]

# 路由表配置
# true 表示创建新的路由表
# false 表示使用已存在的路由表 (需要提供 existing_private_route_table_ids)
create_private_route_tables = true

# 现有路由表 ID (仅在 create_private_route_tables = false 时使用)
# 必须与私有子网数量相同，每个 AZ 的子网对应一个路由表
existing_private_route_table_ids = [
  # "rtb-0123456789abcdef1",  # 示例值，取消注释并按需调整
  # "rtb-0123456789abcdef2"   # 示例值，取消注释并按需调整
]

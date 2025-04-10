region              = "eu-west-1"
vpc_id              = "vpc-0123456789abcdef0"  # 替换为实际的 VPC ID
environment         = "prod"
project             = "internal-network"
single_nat_gateway  = false  # 每个 AZ 部署一个 NAT Gateway 以实现高可用
destination_cidr_block = "10.0.0.0/8"  # 指向内部网络的 CIDR 范围，根据实际情况调整

aws_region = "ap-northeast-1"
vpc_id = "vpc-prod-xxxxx"
private_subnet_ids = ["subnet-prod-aaa", "subnet-prod-bbb", "subnet-prod-ccc"]
bedrock_model_id = "anthropic.claude-3-opus-20240229-v1:0"
bedrock_model_name = "claude-3-opus-prod"

# 生产环境使用更保守的参数配置
bedrock_model_parameters = {
  # 生产环境使用较低的temperature，确保输出更稳定
  temperature = 0.3
  
  # 生产环境可能需要更长的输出
  max_tokens = 8192
  
  # 使用较高的top_p确保输出质量
  top_p = 0.95
  
  # 生产环境使用更严格的top_k
  top_k = 100
  
  # 生产环境的停止序列
  stop_sequences = ["\n\nHuman:", "\n\nAssistant:", "END"]
  
  # 生产环境可能需要更严格的惩罚参数
  frequency_penalty = 0.1
  presence_penalty = 0.1
}

# 生产环境网络安全配置（更严格的访问控制）
allowed_cidr_blocks = ["10.0.0.0/8"]  # 生产环境通常限制更严格

# 生产环境标签
tags = {
  Project     = "bedrock-production"
  Environment = "prod"
  Owner       = "ai-team"
  CostCenter  = "ai-ml-prod"
  DataClass   = "confidential"
  Backup      = "true"
}

# 生产环境建议：
# 1. 使用多可用区部署（多个subnet）
# 2. 启用详细的CloudWatch日志
# 3. 配置适当的IAM角色和权限
# 4. 考虑使用Bedrock的模型调用日志功能
# 5. 设置适当的成本控制措施
# 6. 使用更严格的网络安全策略
# 7. 定期审计IAM权限 
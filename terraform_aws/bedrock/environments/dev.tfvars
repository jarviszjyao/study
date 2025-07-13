aws_region = "ap-northeast-1"
vpc_id = "vpc-xxxxxxxx"
private_subnet_ids = ["subnet-aaaaaaa", "subnet-bbbbbbb"]
bedrock_model_id = "anthropic.claude-3-sonnet-20240229-v1:0"
bedrock_model_name = "claude-3-sonnet-dev"

# Bedrock模型参数配置示例
# 不同模型支持不同的参数，以下是常见参数说明：
bedrock_model_parameters = {
  # Claude模型参数示例
  # temperature: 控制输出的随机性 (0.0-1.0)，0.0最确定性，1.0最随机
  temperature = 0.7
  
  # max_tokens: 生成的最大token数量
  max_tokens = 4096
  
  # top_p: 核采样参数 (0.0-1.0)，控制词汇选择的多样性
  top_p = 0.9
  
  # top_k: 限制每次选择时考虑的词汇数量
  top_k = 250
  
  # stop_sequences: 停止生成的序列列表
  stop_sequences = ["\n\nHuman:", "\n\nAssistant:"]
  
  # 其他可选参数：
  # frequency_penalty: 频率惩罚 (-2.0 到 2.0)
  # presence_penalty: 存在惩罚 (-2.0 到 2.0)
  # anthropic_version: 版本信息
}

# 网络安全配置
allowed_cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]

# 资源标签
tags = {
  Project     = "bedrock-demo"
  Environment = "dev"
  Owner       = "dev-team"
  CostCenter  = "ai-ml"
}

# 常见Bedrock模型ID参考：
# - Claude 3 Sonnet: "anthropic.claude-3-sonnet-20240229-v1:0"
# - Claude 3 Haiku: "anthropic.claude-3-haiku-20240307-v1:0"
# - Claude 3 Opus: "anthropic.claude-3-opus-20240229-v1:0"
# - Llama 2 70B: "meta.llama2-70b-chat-v1"
# - Llama 2 13B: "meta.llama2-13b-chat-v1"
# - Titan Text: "amazon.titan-text-express-v1"
# - Titan Text Lite: "amazon.titan-text-lite-v1"
# - Titan Embeddings: "amazon.titan-embed-text-v1"
# - Cohere Command: "cohere.command-text-v14"
# - Cohere Command Light: "cohere.command-light-text-v14"
# - Mistral 7B: "mistral.mistral-7b-instruct-v0:2"
# - Mistral Large: "mistral.mistral-large-2402-v1:0" 
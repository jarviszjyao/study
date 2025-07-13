# AWS Bedrock 模型参数配置指南

## 概述
本文档详细说明了AWS Bedrock中各种大语言模型的参数配置，帮助您根据不同的使用场景选择合适的参数。

## 通用参数说明

### 1. Temperature (温度)
- **范围**: 0.0 - 1.0
- **作用**: 控制输出的随机性和创造性
- **建议值**:
  - 0.0-0.3: 确定性输出，适合事实性问答
  - 0.3-0.7: 平衡输出，适合一般对话
  - 0.7-1.0: 创造性输出，适合创意写作

### 2. Max Tokens (最大令牌数)
- **作用**: 限制生成文本的最大长度
- **建议值**:
  - 短回答: 256-1024
  - 中等回答: 1024-4096
  - 长回答: 4096-8192

### 3. Top P (核采样)
- **范围**: 0.0 - 1.0
- **作用**: 控制词汇选择的多样性
- **建议值**:
  - 0.9-1.0: 高多样性
  - 0.7-0.9: 中等多样性
  - 0.5-0.7: 低多样性

### 4. Top K
- **作用**: 限制每次选择时考虑的词汇数量
- **建议值**: 50-250

## 模型特定参数

### Claude 系列 (Anthropic)
```hcl
bedrock_model_parameters = {
  temperature = 0.7
  max_tokens = 4096
  top_p = 0.9
  top_k = 250
  stop_sequences = ["\n\nHuman:", "\n\nAssistant:"]
  anthropic_version = "bedrock-2023-05-31"
}
```

### Llama 2 系列 (Meta)
```hcl
bedrock_model_parameters = {
  temperature = 0.7
  max_tokens = 4096
  top_p = 0.9
  top_k = 250
  stop_sequences = ["</s>", "Human:", "Assistant:"]
}
```

### Titan 系列 (Amazon)
```hcl
bedrock_model_parameters = {
  temperature = 0.7
  max_tokens = 4096
  top_p = 0.9
  stop_sequences = ["User:", "Assistant:"]
}
```

### Mistral 系列
```hcl
bedrock_model_parameters = {
  temperature = 0.7
  max_tokens = 4096
  top_p = 0.9
  top_k = 250
  stop_sequences = ["</s>", "Human:", "Assistant:"]
}
```

## 使用场景配置示例

### 1. 客服对话系统
```hcl
bedrock_model_parameters = {
  temperature = 0.3        # 确定性回答
  max_tokens = 2048        # 适中长度
  top_p = 0.95            # 高质量输出
  stop_sequences = ["\n\nHuman:", "\n\nAssistant:"]
}
```

### 2. 创意写作助手
```hcl
bedrock_model_parameters = {
  temperature = 0.8        # 高创造性
  max_tokens = 8192        # 长文本
  top_p = 0.9             # 多样性
  top_k = 300             # 更多选择
}
```

### 3. 代码生成
```hcl
bedrock_model_parameters = {
  temperature = 0.2        # 确定性代码
  max_tokens = 4096        # 代码长度
  top_p = 0.95            # 高质量
  stop_sequences = ["```", "\n\nHuman:", "\n\nAssistant:"]
}
```

### 4. 数据分析报告
```hcl
bedrock_model_parameters = {
  temperature = 0.4        # 平衡
  max_tokens = 6144        # 长报告
  top_p = 0.9             # 多样性
  frequency_penalty = 0.1  # 减少重复
}
```

## 成本优化建议

### 1. 开发环境
- 使用较小的模型 (如 Claude Haiku)
- 较低的 max_tokens
- 较高的 temperature (快速测试)

### 2. 生产环境
- 根据需求选择合适模型
- 精确设置 max_tokens
- 优化 temperature 和 top_p

### 3. 监控指标
- 监控 API 调用次数
- 跟踪 token 使用量
- 设置成本告警

## 安全考虑

### 1. 输入验证
- 验证输入长度
- 检查敏感信息
- 设置适当的超时

### 2. 输出过滤
- 内容安全检查
- 敏感信息过滤
- 输出长度限制

### 3. 访问控制
- IAM 角色权限
- VPC 端点安全组
- API 密钥管理

## 最佳实践

1. **渐进式调优**: 从默认参数开始，逐步调整
2. **A/B 测试**: 对比不同参数的效果
3. **监控反馈**: 收集用户反馈，持续优化
4. **文档记录**: 记录有效的参数组合
5. **版本控制**: 使用版本化的参数配置 
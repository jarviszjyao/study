# 模块集成配置说明

## 问题说明
如果遇到 "Unexpected attribute" 错误，通常是因为：
1. 模块路径不正确
2. 模块输出名称不匹配
3. 模块接口参数不匹配

## 解决步骤

### 1. 确认模块路径
在 `main/main.tf` 中，需要将以下路径替换为您的实际模块路径：

```hcl
# 当前配置
source = "../modules/iam-role"
source = "../modules/security-group"

# 请替换为您的实际路径，例如：
source = "../../../shared/modules/iam-role"
source = "../../../shared/modules/security-group"
```

### 2. 确认模块输出名称
不同的模块可能有不同的输出名称。请检查您的模块输出：

#### IAM Role模块输出检查
```bash
# 查看IAM模块的输出
cd path/to/your/iam-module
terraform output
```

常见的IAM模块输出名称：
- `role_arn`
- `arn`
- `iam_role_arn`
- `role_arn_output`

#### Security Group模块输出检查
```bash
# 查看SG模块的输出
cd path/to/your/security-group-module
terraform output
```

常见的SG模块输出名称：
- `security_group_id`
- `id`
- `sg_id`
- `security_group_arn`

### 3. 调整主程序配置
根据您的模块实际输出名称，调整 `main/main.tf` 中的引用：

```hcl
# 示例：如果您的IAM模块输出是 "arn" 而不是 "role_arn"
iam_role_arn = module.bedrock_iam_role.arn

# 示例：如果您的SG模块输出是 "id" 而不是 "security_group_id"
vpc_endpoint_security_group_ids = [module.bedrock_security_group.id]
```

### 4. 检查模块参数接口
确保传递给模块的参数名称与模块期望的参数名称一致：

#### IAM Role模块参数示例
```hcl
module "bedrock_iam_role" {
  source = "your/iam-module/path"
  
  # 根据您的模块参数名称调整
  role_name = "${var.bedrock_model_name}-role"
  # 或者可能是：
  # name = "${var.bedrock_model_name}-role"
  
  policies = [
    {
      name = "BedrockAccessPolicy"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "bedrock:InvokeModel",
              "bedrock:InvokeModelWithResponseStream",
              "bedrock:ListFoundationModels",
              "bedrock:GetFoundationModel"
            ]
            Resource = "*"
          }
        ]
      })
    }
  ]
  
  # 根据您的模块参数调整
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonBedrockFullAccess"]
  # 或者可能是：
  # policy_arns = ["arn:aws:iam::aws:policy/AmazonBedrockFullAccess"]
  
  tags = var.tags
}
```

#### Security Group模块参数示例
```hcl
module "bedrock_security_group" {
  source = "your/security-group-module/path"
  
  # 根据您的模块参数名称调整
  vpc_id = var.vpc_id
  name   = "${var.bedrock_model_name}-sg"
  # 或者可能是：
  # vpc_id = var.vpc_id
  # sg_name = "${var.bedrock_model_name}-sg"
  
  ingress_rules = [
    {
      port        = 443
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidr_blocks
      description = "HTTPS access from allowed CIDR blocks"
    }
  ]
  
  egress_rules = [
    {
      port        = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound traffic"
    }
  ]
  
  tags = var.tags
}
```

## 调试方法

### 1. 使用 terraform validate
```bash
cd main
terraform validate
```

### 2. 使用 terraform plan 查看详细错误
```bash
terraform plan -var-file="../environments/dev.tfvars"
```

### 3. 检查模块文档
查看您的模块文档，确认：
- 输入参数名称
- 输出参数名称
- 必需的参数

## 常见错误及解决方案

### 错误1: "Unexpected attribute"
**原因**: 模块不接受该属性
**解决**: 检查属性名称是否正确，或该属性是否为必需

### 错误2: "Module not found"
**原因**: 模块路径不正确
**解决**: 确认模块路径，使用绝对路径或相对路径

### 错误3: "Output not found"
**原因**: 模块输出名称不正确
**解决**: 检查模块的实际输出名称

## 测试建议

1. **先单独测试模块**: 确保每个模块都能正常工作
2. **逐步集成**: 先集成一个模块，确认无误后再集成下一个
3. **使用简单配置**: 先用最简单的配置测试，再添加复杂参数 
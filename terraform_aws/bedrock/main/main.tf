terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
  backend "s3" {
    bucket = "your-tfstate-bucket"
    key    = "bedrock/terraform.tfstate"
    region = "ap-northeast-1"
    # 其他backend配置如dynamodb_table等
  }
}

provider "aws" {
  region = var.aws_region
}

# 调用现有的IAM Role模块
module "bedrock_iam_role" {
  source = "../modules/iam-role"  # 请替换为您的IAM模块实际路径
  
  role_name = "${var.bedrock_model_name}-role"
  
  # 根据您的IAM模块参数进行调整
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
  
  # 如果需要附加现有的托管策略
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonBedrockFullAccess"  # 或者更细粒度的策略
  ]
  
  tags = merge({
    Name = "${var.bedrock_model_name}-role"
  }, var.tags)
}

# 调用现有的Security Group模块
module "bedrock_security_group" {
  source = "../modules/security-group"  # 请替换为您的SG模块实际路径
  
  vpc_id = var.vpc_id
  name   = "${var.bedrock_model_name}-sg"
  
  # 根据您的SG模块参数进行调整
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
  
  tags = merge({
    Name = "${var.bedrock_model_name}-sg"
  }, var.tags)
}

# 调用Bedrock模块，使用IAM和SG模块的输出
module "bedrock" {
  source = "../modules/bedrock"

  vpc_id                         = var.vpc_id
  private_subnet_ids             = var.private_subnet_ids
  bedrock_model_id               = var.bedrock_model_id
  bedrock_model_name             = var.bedrock_model_name
  bedrock_model_parameters       = var.bedrock_model_parameters
  vpc_endpoint_security_group_ids = [module.bedrock_security_group.security_group_id]
  # 注意：请根据您的IAM模块实际输出名称调整以下行
  iam_role_arn                   = module.bedrock_iam_role.role_arn
  tags                           = var.tags
} 
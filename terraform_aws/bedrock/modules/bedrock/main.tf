resource "aws_vpc_endpoint" "bedrock" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.bedrock"
  vpc_endpoint_type = "Interface"
  subnet_ids        = var.private_subnet_ids
  security_group_ids = var.vpc_endpoint_security_group_ids
  private_dns_enabled = true
  policy = var.vpc_endpoint_policy
  tags = merge({
    Name = "bedrock-endpoint"
  }, var.tags)
}

data "aws_region" "current" {}

# Bedrock模型服务资源（假设为aws_bedrock_model_inference_endpoint，实际名称请根据provider文档调整）
resource "aws_bedrock_model_inference_endpoint" "this" {
  model_id   = var.bedrock_model_id
  name       = var.bedrock_model_name
  parameters = var.bedrock_model_parameters
  
  # 使用传入的IAM role
  iam_role_arn = var.iam_role_arn
  
  vpc_config {
    vpc_id             = var.vpc_id
    subnet_ids         = var.private_subnet_ids
    security_group_ids = var.vpc_endpoint_security_group_ids
  }
  tags = var.tags
} 
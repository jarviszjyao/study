output "vpc_endpoint_id" {
  description = "The ID of the Bedrock VPC endpoint."
  value       = aws_vpc_endpoint.bedrock.id
}

output "vpc_endpoint_dns_entry" {
  description = "The DNS entry for the Bedrock VPC endpoint."
  value       = aws_vpc_endpoint.bedrock.dns_entry
}

output "bedrock_model_endpoint_id" {
  description = "The ID of the Bedrock model inference endpoint."
  value       = aws_bedrock_model_inference_endpoint.this.id
}

output "bedrock_model_endpoint_name" {
  description = "The name of the Bedrock model inference endpoint."
  value       = aws_bedrock_model_inference_endpoint.this.name
}

output "iam_role_arn" {
  description = "The ARN of the IAM role used by Bedrock."
  value       = var.iam_role_arn
} 
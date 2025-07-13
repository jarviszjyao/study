variable "vpc_id" {
  description = "The ID of the VPC where Bedrock will be deployed."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for Bedrock deployment."
  type        = list(string)
}

variable "bedrock_model_id" {
  description = "The ID of the Bedrock model to deploy."
  type        = string
}

variable "bedrock_model_name" {
  description = "The name of the Bedrock model."
  type        = string
}

variable "bedrock_model_parameters" {
  description = "Map of parameters for the Bedrock model."
  type        = map(any)
  default     = {}
}

variable "vpc_endpoint_security_group_ids" {
  description = "List of security group IDs to associate with the VPC endpoint."
  type        = list(string)
}

variable "iam_role_arn" {
  description = "ARN of the IAM role to use for Bedrock."
  type        = string
}

variable "vpc_endpoint_policy" {
  description = "The policy document to attach to the VPC endpoint. Leave empty for default (allow all)."
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags to assign to resources."
  type        = map(string)
  default     = {}
} 
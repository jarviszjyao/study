variable "aws_region" {
  description = "AWS region to deploy resources."
  type        = string
}

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

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access Bedrock."
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

variable "tags" {
  description = "A map of tags to assign to resources."
  type        = map(string)
  default     = {}
} 
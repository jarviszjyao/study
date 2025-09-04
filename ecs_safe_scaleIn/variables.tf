variable "region" { type = string }
variable "project_name" { type = string }
variable "env" { type = string }

# ECS cluster and service names are no longer needed as we get them from the event

variable "kamailio_lambda_arn" { type = string }

variable "asterisk_http_port" { type = number  default = 8080 }
variable "asterisk_http_scheme" { type = string  default = "http" }

variable "drain_timeout_seconds" { type = number  default = 14400 }
variable "drain_concurrency_limit" { type = number  default = 1 }

variable "shared_token" { type = string  sensitive = true }



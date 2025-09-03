variable "region" { type = string }
variable "project_name" { type = string }
variable "env" { type = string }

variable "ecs_cluster_name" { type = string }
variable "ecs_service_name" { type = string }

variable "kamailio_lambda_arn" { type = string }

variable "asterisk_http_port" { type = number  default = 8080 }
variable "asterisk_http_scheme" { type = string  default = "http" }

variable "drain_timeout_seconds" { type = number  default = 14400 }
variable "drain_concurrency_limit" { type = number  default = 1 }

variable "shared_token" { type = string  sensitive = true }



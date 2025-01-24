provider "aws" {
  region = var.region
}

module "ecs_eventbridge_rds" {
  source               = "./modules/ecs_eventbridge_rds"
  region               = var.region
  cluster_name         = var.cluster_name
  task_name            = var.task_name
  schedule_expression  = var.schedule_expression
  rds_endpoint         = var.rds_endpoint
  rds_database         = var.rds_database
  rds_resource_arn     = var.rds_resource_arn
  s3_bucket_arn        = var.s3_bucket_arn
  subnets              = var.subnets
  security_groups      = var.security_groups
}

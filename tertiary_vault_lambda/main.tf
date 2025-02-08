provider "aws" {
  region = var.aws_region
}

module "lambda_backup" {
  source = "./modules/lambda_backup"

  lambda_function_name  = var.lambda_function_name
  image_uri             = var.image_uri
  ephemeral_storage_size = var.ephemeral_storage_size
  vpc_config            = var.vpc_config
  rds_config            = var.rds_config
  s3_config             = var.s3_config
  lambda_performance    = var.lambda_performance
  event_schedule        = var.event_schedule
  function_timeout      = var.function_timeout
  function_memory_size  = var.function_memory_size
  tags                  = var.tags
}

provider "aws" {
  region = var.aws_region
}

module "lambda_backup" {
  source = "./modules/lambda_backup"

  lambda_function_name = var.lambda_function_name
  image_uri            = var.image_uri
  vpc_config           = var.vpc_config
  rds_config           = var.rds_config
  s3_config            = var.s3_config
  lambda_performance   = var.lambda_performance
  lambda_monitoring    = var.lambda_monitoring
  event_schedule       = var.event_schedule
  tags                 = var.tags
}

provider "aws" {
  region = local.region

  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true

  endpoints {
    cloudformation = local.localstack_endpoint
    cloudwatch     = local.localstack_endpoint
    iam            = local.localstack_endpoint
    lambda         = local.localstack_endpoint
    apigateway     = local.localstack_endpoint
  }
}

module "iam" {
  source      = "./modules/iam"
  common_tags = local.common_tags
}

module "lambda" {
  source                = "./modules/lambda"
  common_tags           = local.common_tags
  region                = local.region
  lambda_execution_role = module.iam.lambda_execution_role
}


module "apigateway" {
  source                     = "./modules/apigateway"
  lambda_alias               = module.lambda.lambda_alias_arn
  lambda_function_name       = module.lambda.lambda_function_name
  lambda_alias_name          = module.lambda.lambda_alias_name
  lambda_alias_function_name = module.lambda.lambda_alias_function_name
  region                     = local.region
  environment                = var.environment
  common_tags                = local.common_tags
}
locals {
  region                 = "eu-west-1"
  localstack_endpoint    = "https://localhost.localstack.cloud:4566"
  localstack_s3_endpoint = "http://s3.localhost.localstack.cloud:4566"

  common_tags = {
    Environment = var.environment
  }
}
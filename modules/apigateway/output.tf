output "invoke_url" {
  value = "http://${aws_api_gateway_rest_api.api.id}.execute-api.localhost.localstack.cloud:4566"
}
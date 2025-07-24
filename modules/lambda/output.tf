output "lambda_alias_name" {
  description = "Name of the Lambda alias"
  value       = aws_lambda_alias.live.name
}

output "lambda_alias_function_name" {
  description = "Name of the Lambda alias"
  value       = aws_lambda_alias.live.function_name
}

output "lambda_alias_arn" {
  description = "ARN of the Lambda alias"
  value       = aws_lambda_alias.live.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.lambda.function_name
}
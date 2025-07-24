output "lambda_execution_role" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_exec.arn
}
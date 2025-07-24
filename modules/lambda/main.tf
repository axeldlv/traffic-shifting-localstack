resource "aws_lambda_function" "lambda" {
  filename         = "${path.root}/lambda/v1/lambda-v1.zip"
  function_name    = var.lambda_name
  role             = var.lambda_execution_role
  handler          = var.handler
  source_code_hash = filebase64sha256("${path.root}/lambda/v1/lambda-v1.zip")
  runtime          = var.runtime
  publish          = true

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [filename, source_code_hash]
  }

  tags = merge(var.common_tags, {
    Name         = "${var.lambda_name}"
    FunctionName = var.lambda_name
  })
}

resource "aws_lambda_alias" "live" {
  name             = "live"
  function_name    = aws_lambda_function.lambda.function_name
  function_version = aws_lambda_function.lambda.version

  routing_config {
    additional_version_weights = {}
  }
}

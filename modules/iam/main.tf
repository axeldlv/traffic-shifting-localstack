resource "aws_iam_role" "lambda_exec" {
  name = "lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Effect = "Allow",
      Sid    = ""
    }]
  })

  tags = merge(var.common_tags, {
    Name = "lambda-execution-role"
  })
}
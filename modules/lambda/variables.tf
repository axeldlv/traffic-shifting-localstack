variable "common_tags" {
  description = "common_tags"
  type        = map(string)
  default     = {}
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.13"
}

variable "handler" {
  description = "Lambda handler"
  type        = string
  default     = "application.handler"
}

variable "lambda_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "lambda_function"
}

variable "lambda_execution_role" {
  description = "IAM role ARN for Lambda"
  type        = string
  default     = ""
}

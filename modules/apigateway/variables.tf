variable "common_tags" {
  description = "common_tags"
  type        = map(string)
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "lambda_alias" {
  type        = string
  description = "Lambda alias for traffic shifting deployment"
}

variable "lambda_function_name" {
  type        = string
  description = "Name of the Lambda function"
}

variable "lambda_alias_name" {
  type        = string
  description = "Name of the Lambda alias"
}

variable "lambda_alias_function_name" {
  type        = string
  description = "Name of the Lambda alias function"
}

variable "region" {
  description = "Get region"
  type        = string
}
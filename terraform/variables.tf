variable "aws_region" {
  description = "The AWS region to create things in."
  default     = "ap-southeast-1"
}

variable "lambda_function_name" {
  default = "goofyahh-cat-webhook"
}

// load environment variables
locals {
  env = { for tuple in regexall("(.*)=(.*)", file("../.env")) : tuple[0] => sensitive(tuple[1]) }
}
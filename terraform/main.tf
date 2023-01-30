terraform {
	required_providers {
		aws = {
			source = "hashicorp/aws"
		}
	}
}
 
provider "aws" {
 	region = "ap-southeast-1"
}
 
resource "aws_lambda_function" "example" {
  function_name = "lambda_function"
  runtime = "python3.9"
  role = aws_iam_role.lambda_role.arn
  handler = "lambda_function.lambda_handler"
  source_code_hash = filebase64sha256("../lambda_function.zip")
}

resource "aws_iam_role" "lambda_role" {
  name = "iam_for_lambda"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_policy" {
  name = "example_lambda_policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:*"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_cloudwatch_event_rule" "example" {
  name = "terraform_lambda_rule"
  schedule_expression = "rate(3 minutes)"
}

resource "aws_cloudwatch_event_target" "example" {
  rule = aws_cloudwatch_event_rule.example.name
  target_id = "terraform_lambda_target"
  arn = aws_lambda_function.example.arn
}
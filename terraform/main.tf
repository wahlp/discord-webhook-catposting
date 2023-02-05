terraform {
  required_providers {
    # https://registry.terraform.io/providers/jrhouston/dotenv/latest/docs
    dotenv = {
      source = "jrhouston/dotenv"
      version = "1.0.1"
    }
  }
}

provider "dotenv" {
  # Configuration options
}

provider "aws" {
  region = "${var.aws_region}"
}

provider "archive" {}

data dotenv config {
  filename = "../.env"
}

data "archive_file" "zip" {
  type        = "zip"
  source_file = "../lambda_function.py"
  output_path = "../lambda_function.zip"
}

data "aws_iam_policy_document" "policy" {
  statement {
    sid    = ""
    effect = "Allow"

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = "${data.aws_iam_policy_document.policy.json}"
}

resource "aws_lambda_function" "lambda" {
  function_name = "lambda_function"

  filename         = "${data.archive_file.zip.output_path}"
  source_code_hash = "${data.archive_file.zip.output_base64sha256}"

  role    = "${aws_iam_role.iam_for_lambda.arn}"
  handler = "lambda_function.lambda_handler"
  runtime = "python3.9"
  
  environment {
    variables = {
      WEBHOOK_URL = data.dotenv.config.env["WEBHOOK_URL"]
    }
  }
}

resource "aws_cloudwatch_event_rule" "lambda_trigger" {
  name = "lambda_trigger"
  schedule_expression = "rate(3 minutes)"
}

resource "aws_cloudwatch_event_target" "example" {
  rule = aws_cloudwatch_event_rule.lambda_trigger.name
  target_id = "lambda"
  arn = aws_lambda_function.lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_check_foo" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.lambda.function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.lambda_trigger.arn
}
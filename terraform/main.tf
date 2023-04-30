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

# create iam role with perms
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

# create lambda function
resource "aws_lambda_function" "lambda" {
  function_name = var.lambda_function_name

  filename         = "${data.archive_file.zip.output_path}"
  source_code_hash = "${data.archive_file.zip.output_base64sha256}"

  role    = "${aws_iam_role.iam_for_lambda.arn}"
  handler = "lambda_function.lambda_handler"
  runtime = "python3.9"
  
  environment {
    variables = {
      WEBHOOK_URL = data.dotenv.config.env["WEBHOOK_URL"]
      TENOR_API_KEY = data.dotenv.config.env["TENOR_API_KEY"]
    }
  }
}

# create cloudwatch event and set lambda as target
# https://stackoverflow.com/questions/35895315/use-terraform-to-set-up-a-lambda-function-triggered-by-a-scheduled-event-source
resource "aws_cloudwatch_event_rule" "lambda_trigger" {
  name = "discord-webhook-post"
  schedule_expression = "cron(0 4,16 * * ? *)"
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

# cloudwatch logs
resource "aws_cloudwatch_log_group" "example" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 14
}

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}
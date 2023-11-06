
resource "aws_cloudwatch_event_target" "lambda" {
  target_id = "lambda-function-target"
  rule      = aws_cloudwatch_event_rule.ram.name
  arn       = aws_lambda_alias.tagger_alias.arn
}

data "archive_file" "lambda_tagger" {
  type        = "zip"
  source_file = "${path.module}/lambda/subnet-tagger.py"
  output_path = "${path.module}/lambda/subnet-tagger.zip"
}

resource "aws_lambda_function" "tagger" {
  description   = "Tag subnets in team account"
  function_name = "lambda-subnet-tagger"

  filename         = data.archive_file.lambda_tagger.output_path
  source_code_hash = data.archive_file.lambda_tagger.output_base64sha256
  timeout          = 5

  role    = aws_iam_role.lambda_tagger.arn
  handler = "subnet-tagger.lambda_handler"
  runtime = "python3.9"

  publish = true
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tagger.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ram.arn
  qualifier     = aws_lambda_alias.tagger_alias.name
}

resource "aws_lambda_alias" "tagger_alias" {
  name             = "taggeralias"
  description      = "Lambda alias for tagger function"
  function_name    = aws_lambda_function.tagger.function_name
  function_version = "$LATEST"
}

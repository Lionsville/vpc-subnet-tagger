resource "aws_iam_policy" "lambda_role_policy" {
  name   = "lambda-role-policy"
  policy = data.aws_iam_policy_document.lambda_role_policy.json
}


resource "aws_iam_role" "lambda_tagger" {
  name               = "tagger-lambdaRole"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

resource "aws_iam_policy_attachment" "lambda_role_policy" {
  name       = "lambda-role-policy-attachment"
  policy_arn = aws_iam_policy.lambda_role_policy.arn
  roles      = [aws_iam_role.lambda_tagger.name]
}

resource "aws_iam_policy_attachment" "lambda_basic_role_policy" {
  name       = "lambda-basic-role-policy-attachment"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  roles      = [aws_iam_role.lambda_tagger.name]
}

resource "aws_cloudwatch_event_rule" "ram" {
  name        = "capture-ram-creation"
  description = "Capture creation of RAM shares"

  event_pattern = jsonencode({
    "source" : ["aws.ram"],
    "detail-type" : ["AWS API Call via CloudTrail"],
    "detail" : {
      "eventSource" : ["ram.amazonaws.com"],
      "eventName" : ["AssociateResourceShare"]
    }
  })
}

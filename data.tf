data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_role_policy" {
  statement {
    sid       = "LambdaRolePolicy"
    effect    = "Allow"
    actions   = ["ec2:DescribeSubnets"]
    resources = ["*"]
  }
  statement {
    sid       = "LambdaAssumeRolePolicy"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::*:role/LambdaTaggerRole"]
  }
}

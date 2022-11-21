resource "aws_iam_role" "streaming" {
  name               = "streaming"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}
data "aws_iam_policy_document" "assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type       = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "vpc_access" {
  policy_arn = data.aws_iam_policy.vpc_access.arn
  role       = aws_iam_role.streaming.name
}
data "aws_iam_policy" "vpc_access" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_policy" "access" {
  name   = "streaming"
  policy = data.aws_iam_policy_document.access.json
}
resource "aws_iam_role_policy_attachment" "access" {
  policy_arn = aws_iam_policy.access.arn
  role       = aws_iam_role.streaming.name
}

data "aws_iam_policy_document" "access" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
    effect = "Allow"
  }
  statement {
    actions = [
      "dynamodb:GetShardIterator",
      "dynamodb:DescribeStream",
      "dynamodb:GetRecords"
    ]
    resources = [var.dynamodb_table_arn]
    effect    = "Allow"
  }
  statement {
    actions = [
      "es:ESHttpPost"
    ]
    resources = ["*"]
    effect    = "Allow"
  }
}

data "aws_iam_policy_document" "main" {
  statement {
    principals {
      type        = "AWS"
      identifiers  = ["*"]
    }
    effect  = "Allow"
    actions = ["es:*"]
  }
}
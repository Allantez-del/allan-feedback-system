resource "aws_dynamodb_table" "feedback" {
  name         = "allan-feedback"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "feedbackId"

  attribute {
    name = "feedbackId"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Project     = "Allan Feedback System"
    Environment = "dev"
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "allan-feedback-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "lambda.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "allan-feedback-dynamodb-write"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "dynamodb:PutItem"
        ]

        Resource = aws_dynamodb_table.feedback.arn
      }
    ]
  })
}

resource "aws_lambda_function" "feedback" {
  function_name = "allan-feedback-handler"

  filename         = "${path.module}/../lambda/feedback_handler.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambda/feedback_handler.zip")

  role    = aws_iam_role.lambda_exec.arn
  handler = "feedback_handler.handler"
  runtime = "python3.13"

  environment {
    variables = {
      FEEDBACK_TABLE_NAME = aws_dynamodb_table.feedback.name
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy.lambda_dynamodb
  ]

  tags = {
    Project     = "Allan Feedback System"
    Environment = "dev"
  }
}
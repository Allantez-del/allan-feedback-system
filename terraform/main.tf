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

resource "aws_apigatewayv2_api" "feedback_api" {
  name          = "allan-feedback-api"
  protocol_type = "HTTP"

  tags = {
    Project     = "Allan Feedback System"
    Environment = "dev"
  }
}

resource "aws_apigatewayv2_integration" "feedback_lambda" {
  api_id = aws_apigatewayv2_api.feedback_api.id

  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.feedback.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "post_feedback" {
  api_id = aws_apigatewayv2_api.feedback_api.id

  route_key = "POST /feedback"
  target    = "integrations/${aws_apigatewayv2_integration.feedback_lambda.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id = aws_apigatewayv2_api.feedback_api.id

  name        = "$default"
  auto_deploy = true

  tags = {
    Project     = "Allan Feedback System"
    Environment = "dev"
  }
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.feedback.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.feedback_api.execution_arn}/*/*"
}
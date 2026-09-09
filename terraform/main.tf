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
    Project     = var.project_name
    Environment = var.environment
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
          "dynamodb:PutItem",
          "dynamodb:Scan"
        ]

        Resource = aws_dynamodb_table.feedback.arn
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "feedback_lambda" {
  name              = "/aws/lambda/allan-feedback-handler"
  retention_in_days = 14

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
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
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_apigatewayv2_api" "feedback_api" {
  name          = "allan-feedback-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_headers = [
      "content-type",
      "authorization"
    ]

    allow_methods = [
      "GET",
      "POST",
      "OPTIONS"
    ]

    allow_origins = [
      "*"
    ]

    max_age = 300
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
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

resource "aws_apigatewayv2_route" "get_feedback" {
  api_id = aws_apigatewayv2_api.feedback_api.id

  route_key          = "GET /feedback"
  target             = "integrations/${aws_apigatewayv2_integration.feedback_lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.staff_jwt.id
}

resource "aws_apigatewayv2_authorizer" "staff_jwt" {
  api_id = aws_apigatewayv2_api.feedback_api.id

  authorizer_type = "JWT"
  name            = "allan-feedback-staff-jwt"

  identity_sources = [
    "$request.header.Authorization"
  ]

  jwt_configuration {
    audience = [
      aws_cognito_user_pool_client.staff.id
    ]

    issuer = "https://cognito-idp.eu-central-1.amazonaws.com/${aws_cognito_user_pool.staff.id}"
  }
}

resource "aws_apigatewayv2_stage" "default" {
  api_id = aws_apigatewayv2_api.feedback_api.id

  name        = "$default"
  auto_deploy = true

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.feedback.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.feedback_api.execution_arn}/*/*"
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name        = "allan-feedback-lambda-errors"
  alarm_description = "Alarm when the Allan Feedback Lambda reports errors."

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.feedback.function_name
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_cognito_user_pool" "staff" {
  name = "allan-feedback-staff"

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_cognito_user_pool_client" "staff" {
  name         = "allan-feedback-staff-client"
  user_pool_id = aws_cognito_user_pool.staff.id

  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  prevent_user_existence_errors = "ENABLED"
}

resource "aws_cloudwatch_dashboard" "feedback" {
  dashboard_name = "allan-feedback-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "Lambda - Requests and Errors"
          region = var.aws_region
          view   = "timeSeries"

          metrics = [
            [
              "AWS/Lambda",
              "Invocations",
              "FunctionName",
              aws_lambda_function.feedback.function_name,
              {
                stat = "Sum"
              }
            ],
            [
              ".",
              "Errors",
              ".",
              ".",
              {
                stat = "Sum"
              }
            ],
            [
              ".",
              "Throttles",
              ".",
              ".",
              {
                stat = "Sum"
              }
            ]
          ]

          period = 300
        }
      },

      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "Lambda - Duration"
          region = var.aws_region
          view   = "timeSeries"

          metrics = [
            [
              "AWS/Lambda",
              "Duration",
              "FunctionName",
              aws_lambda_function.feedback.function_name,
              {
                stat = "Average"
              }
            ]
          ]

          period = 300
        }
      },

      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "API Gateway - Requests and Errors"
          region = var.aws_region
          view   = "timeSeries"

          metrics = [
            [
              "AWS/ApiGateway",
              "Count",
              "ApiId",
              aws_apigatewayv2_api.feedback_api.id,
              "Stage",
              aws_apigatewayv2_stage.default.name,
              {
                stat = "Sum"
              }
            ],
            [
              ".",
              "4xx",
              ".",
              ".",
              ".",
              ".",
              {
                stat = "Sum"
              }
            ],
            [
              ".",
              "5xx",
              ".",
              ".",
              ".",
              ".",
              {
                stat = "Sum"
              }
            ]
          ]

          period = 300
        }
      },

      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "DynamoDB - Capacity"
          region = var.aws_region
          view   = "timeSeries"

          metrics = [
            [
              "AWS/DynamoDB",
              "ConsumedReadCapacityUnits",
              "TableName",
              aws_dynamodb_table.feedback.name,
              {
                stat = "Sum"
              }
            ],
            [
              ".",
              "ConsumedWriteCapacityUnits",
              ".",
              ".",
              {
                stat = "Sum"
              }
            ]
          ]

          period = 300
        }
      },

      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 24
        height = 6

        properties = {
          title  = "DynamoDB - Throttling"
          region = var.aws_region
          view   = "timeSeries"

          metrics = [
            [
              "AWS/DynamoDB",
              "ReadThrottleEvents",
              "TableName",
              aws_dynamodb_table.feedback.name,
              {
                stat = "Sum"
              }
            ],
            [
              ".",
              "WriteThrottleEvents",
              ".",
              ".",
              {
                stat = "Sum"
              }
            ]
          ]

          period = 300
        }
      }
    ]
  })
}
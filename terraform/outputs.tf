output "api_endpoint" {
  description = "Base URL of the Customer Feedback API"
  value       = aws_apigatewayv2_api.feedback_api.api_endpoint
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID for staff authentication"
  value       = aws_cognito_user_pool.staff.id
}

output "cognito_app_client_id" {
  description = "Cognito App Client ID for staff authentication"
  value       = aws_cognito_user_pool_client.staff.id
}

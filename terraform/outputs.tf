output "api_endpoint" {
  description = "Base URL of the Customer Feedback API"
  value       = aws_apigatewayv2_api.feedback_api.api_endpoint
}

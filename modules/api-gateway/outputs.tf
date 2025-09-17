output "api_endpoint" {
  description = "The invocation URL of the API Gateway."
  value       = aws_apigatewayv2_stage.this.invoke_url
}

output "api_id" {
  description = "The ID of the API Gateway."
  value       = aws_apigatewayv2_api.this.id
}
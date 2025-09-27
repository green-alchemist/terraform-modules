output "api_endpoint" {
  description = "The invocation URL of the API Gateway."
  value       = aws_apigatewayv2_stage.this.invoke_url
}

output "api_id" {
  description = "The ID of the API Gateway."
  value       = aws_apigatewayv2_api.this.id
}

output "api_gateway_hosted_zone_id" {
  description = "The hosted zone ID of the API Gateway custom domain name."
  value       = aws_apigatewayv2_domain_name.this.domain_name_configuration[0].hosted_zone_id
}

output "api_gateway_target_domain_name" {
  description = "The target domain name of the API Gateway custom domain."
  value       = aws_apigatewayv2_domain_name.this.domain_name_configuration[0].target_domain_name
}

output "execution_arn" {
  description = "The execution ARN of the API Gateway."
  value       = aws_apigatewayv2_api.this.execution_arn
}

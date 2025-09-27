# modules/lambda-proxy/outputs.tf

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.proxy.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.proxy.arn
}

output "lambda_function_invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = aws_lambda_function.proxy.invoke_arn
}

output "lambda_function_qualified_arn" {
  description = "Qualified ARN of the Lambda function (includes version)"
  value       = aws_lambda_function.proxy.qualified_arn
}

output "lambda_function_version" {
  description = "Latest published version of the Lambda function"
  value       = aws_lambda_function.proxy.version
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda.arn
}

output "lambda_role_name" {
  description = "Name of the Lambda execution role"
  value       = aws_iam_role.lambda.name
}

output "lambda_security_group_id" {
  description = "Security group ID of the Lambda function"
  value       = aws_security_group.lambda.id
}

output "lambda_log_group_name" {
  description = "CloudWatch log group name for Lambda"
  value       = aws_cloudwatch_log_group.lambda.name
}

output "lambda_log_group_arn" {
  description = "CloudWatch log group ARN for Lambda"
  value       = aws_cloudwatch_log_group.lambda.arn
}

output "lambda_error_alarm_arn" {
  description = "ARN of the Lambda error CloudWatch alarm"
  value       = var.enable_monitoring ? aws_cloudwatch_metric_alarm.lambda_errors[0].arn : null
}

output "lambda_throttle_alarm_arn" {
  description = "ARN of the Lambda throttle CloudWatch alarm"
  value       = var.enable_monitoring ? aws_cloudwatch_metric_alarm.lambda_throttles[0].arn : null
}
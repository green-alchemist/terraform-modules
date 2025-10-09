output "lambda_invoke_arn" {
  value       = aws_lambda_function.wake_proxy.invoke_arn
  description = "The invoke ARN of the Lambda function."
}

output "lambda_arn" {
  value       = aws_lambda_function.wake_proxy.arn
  description = "The ARN of the Lambda function."
}

output "lambda_function_name" {
  value       = aws_lambda_function.wake_proxy.function_name
  description = "The name of the Lambda function."
}
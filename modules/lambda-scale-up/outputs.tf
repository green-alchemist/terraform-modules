output "lambda_arn" {
  value       = aws_lambda_function.scale_trigger.invoke_arn
  description = "The invoke ARN of the Lambda function."
}

output "lambda_function_name" {
  value       = aws_lambda_function.scale_trigger.function_name
  description = "The name of the Lambda function."
}
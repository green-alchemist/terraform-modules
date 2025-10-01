output "lambda_arn" {
  value       = aws_lambda_function.scale_trigger.arn
  description = "ARN of the Lambda function."
}
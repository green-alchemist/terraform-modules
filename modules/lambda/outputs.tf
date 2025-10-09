output "lambda_invoke_arns" {
  value = {
    for name, lambda in aws_lambda_function.this : name => lambda.invoke_arn
  }
  description = "Map of Lambda invoke ARNs, keyed by Lambda configuration name."
}

output "lambda_arns" {
  value = {
    for name, lambda in aws_lambda_function.this : name => lambda.arn
  }
  description = "Map of Lambda ARNs, keyed by Lambda configuration name."
}

output "lambda_function_names" {
  value = {
    for name, lambda in aws_lambda_function.this : name => lambda.function_name
  }
  description = "Map of Lambda function names, keyed by Lambda configuration name."
}
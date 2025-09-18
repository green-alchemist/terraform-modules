output "parameter_arns" {
  description = "A map of the ARNs of the created SSM parameters."
  value       = { for key, param in aws_ssm_parameter.this : key => param.arn }
}

output "parameter_names" {
  description = "A map of the names of the created SSM parameters."
  value       = { for key, param in aws_ssm_parameter.this : key => param.name }
}

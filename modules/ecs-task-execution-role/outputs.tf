output "execution_role_arn" {
  description = "The ARN of the ECS Task Execution Role."
  value       = aws_iam_role.execution_role.arn
}

output "execution_role_name" {
  description = "The name of the ECS Task Execution Role."
  value       = aws_iam_role.execution_role.name
}

output "task_role_arn" {
  description = "The ARN of the ECS Task Role."
  value       = aws_iam_role.task_role.arn
}

output "task_role_name" {
  description = "The name of the ECS Task Role."
  value       = aws_iam_role.task_role.name
}

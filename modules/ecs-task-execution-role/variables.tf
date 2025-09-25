variable "execution_role_name" {
  description = "The name for the ECS Task Execution Role."
  type        = string
}

variable "task_role_name" {
  description = "The name for the ECS Task Role."
  type        = string
}

variable "task_role_policy_json" {
  description = "A JSON IAM policy document that grants permissions to the application running in the container."
  type        = string
  default     = null
}

variable "attach_ssm_secrets_policy" {
  description = "If true, attaches a policy to the Execution Role allowing it to fetch secrets from SSM and Secrets Manager."
  type        = bool
  default     = false
}

variable "secrets_ssm_path" {
  description = "The SSM path to grant GetParameters access to. Required if attach_ssm_secrets_policy is true."
  type        = string
  default     = "*"
}

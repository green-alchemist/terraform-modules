variable "lambda_name" {
  type        = string
  description = "Lambda name."
}

variable "lambda_configs" {
  type = list(object({
    name        = string
    code        = string
    timeout     = number
    memory_size = number
    permissions = list(object({
      Action   = string
      Resource = string
    }))
    environment = map(string)
    vpc_config = object({
      subnet_ids         = list(string)
      security_group_ids = list(string)
    })
  }))
  description = "List of Lambda configurations (name, code, timeout, memory, permissions, env vars, VPC)"
  default     = []
}
variable "lambda_name" {
  type        = string
  description = "Lambda name."
}

variable "lambda_configs" {
  type = list(object({
    name            = string
    code            = string
    filename        = optional(string)
    python_packages = optional(list(string), [])
    timeout         = number
    memory_size     = number
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

  validation {
    condition = alltrue([
      for cfg in var.lambda_configs :
      (length(cfg.vpc_config.subnet_ids) == 0 && length(cfg.vpc_config.security_group_ids) == 0) ||
      (length(cfg.vpc_config.subnet_ids) > 0 && length(cfg.vpc_config.security_group_ids) > 0)
    ])
    error_message = "Each Lambda config must have both subnet_ids and security_group_ids as non-empty lists or both as empty lists."
  }
}
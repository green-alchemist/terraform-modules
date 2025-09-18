variable "parameters" {
  description = "A map of SSM parameters to create. The key is the parameter name."
  type = map(object({
    value       = string
    type        = optional(string, "String")
    description = optional(string)
    tier        = optional(string, "Standard")
    overwrite   = optional(bool, false)
  }))
  default = {}
}

variable "tags" {
  description = "A map of tags to assign to the SSM parameters."
  type        = map(string)
  default     = {}
}

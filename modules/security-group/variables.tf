variable "name" {
  description = "The name of the security group."
  type        = string
}

variable "description" {
  description = "The description of the security group."
  type        = string
  default     = "Managed by Terraform"
}

variable "vpc_id" {
  description = "The ID of the VPC."
  type        = string
}

variable "ingress_rules" {
  description = "A list of ingress rules to apply to the security group."
  type = list(object({
    from_port       = number
    to_port         = number
    protocol        = string
    # One of the following two is required
    cidr_blocks     = optional(list(string))
    security_groups = optional(list(string))
  }))
  default = []
}

variable "egress_rules" {
  description = "A list of egress rules to apply to the security group."
  type = list(object({
    from_port       = number
    to_port         = number
    protocol        = string
    # One of the following two is required
    cidr_blocks     = optional(list(string))
    security_groups = optional(list(string))
  }))
  default = []
}
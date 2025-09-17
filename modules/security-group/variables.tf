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
  description = "A list of ingress rules."
  type        = any
  default     = []
}

variable "egress_rules" {
  description = "A list of egress rules."
  type        = any
  default     = []
}
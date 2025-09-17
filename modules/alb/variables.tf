variable "name" {
  description = "The name for the ALB and related resources."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC."
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs to attach the ALB to."
  type        = list(string)
}

variable "security_group_ids" {
  description = "A list of security group IDs to attach to the ALB."
  type        = list(string)
}
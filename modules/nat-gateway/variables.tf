variable "name" {
  description = "The name for the NAT Gateway and related resources."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC."
  type        = string
}

variable "subnet_id" {
  description = "The ID of the public subnet in which to place the NAT Gateway."
  type        = string
}

variable "private_subnet_ids" {
  description = "A list of private subnet IDs to associate with the NAT Gateway's route table."
  type        = list(string)
}
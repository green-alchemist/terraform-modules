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

variable "public_subnet_ids" {
  description = "A list of public subnet IDs to associate with the NAT Gateway's route table."
  type        = list(string)
}

variable "public_subnets_map" {
  description = "A map of public subnet objects to associate with the public route table."
  type        = map(object({ id = string }))
  default     = {}
}

variable "private_subnets_map" {
  description = "A map of private subnet objects to associate with the private route table."
  type        = map(object({ id = string }))
  default     = {}
}
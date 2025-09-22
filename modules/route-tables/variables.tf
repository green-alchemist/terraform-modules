variable "vpc_id" {
  description = "The ID of the VPC."
  type        = string
}

variable "name_prefix" {
  description = "A prefix for the names of the route tables."
  type        = string
}

variable "internet_gateway_id" {
  description = "The ID of the Internet Gateway for the public route table."
  type        = string
  default     = null
}

variable "create_public_route_table" {
  description = "Flag to control the creation of a public route table."
  type        = bool
  default     = false
}

variable "create_private_route_table" {
  description = "Flag to control the creation of a private route table."
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default     = {}
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
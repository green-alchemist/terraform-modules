variable "route_table_name" {
  description = "The Name of the Route Table"
  type        = string
  default     = "Free Tier Route Table"
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  type        = string
}

variable "subnet_ids" {
  description = "A map of subnet objects to associate with the route table."
  type        = map(object({ id = string }))
  default     = {}
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default     = {}
}

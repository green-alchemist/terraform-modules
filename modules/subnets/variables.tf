variable "vpc_id" {
  description = "The ID of the VPC."
  type        = string
}

variable "name_prefix" {
  description = "A prefix to use for the subnet names (e.g., 'public' or 'private')."
  type        = string
}

variable "subnets" {
  description = "A map of Availability Zones to CIDR blocks for the subnets."
  type        = map(string)
}

variable "assign_public_ip_on_launch" {
  description = "If true, instances launched into this subnet will be assigned a public IP address."
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default     = {}
}
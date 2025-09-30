variable "service_name" {
  type        = string
  description = "Name of the service (e.g., strapi-admin) used for naming the bastion resources."
}

variable "public_subnet_id" {
  type        = string
  description = "ID of the public subnet where the bastion host will be deployed."
}

variable "bastion_security_group_id" {
  type        = string
  description = "ID of the security group to attach to the bastion host, allowing outbound traffic for SSM and optional intra-VPC access."
}
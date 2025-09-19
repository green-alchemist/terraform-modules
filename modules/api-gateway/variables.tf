variable "name" {
  description = "The name for the API Gateway and related resources."
  type        = string
}

variable "stage_name" {
  description = "The name of the deployment stage (e.g., 'staging')."
  type        = string
  default     = "$default"
}

variable "subnet_ids" {
  description = "A list of subnet IDs for the VPC Link."
  type        = list(string)
}

variable "security_group_ids" {
  description = "A list of security group IDs for the VPC Link."
  type        = list(string)
}

variable "private_dns_name" {
  description = "The private DNS name of the target service."
  type        = string
}

variable "container_port" {
  description = "The port of the target container."
  type        = number
}

variable "fargate_service_arn" {
  description = "The ARN of the Fargate service this API Gateway integrates with. Used to enforce dependency order."
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "The custom domain name for the API Gateway."
  type        = string
}

variable "acm_certificate_arn" {
  description = "The ARN of the ACM certificate for the custom domain."
  type        = string
}
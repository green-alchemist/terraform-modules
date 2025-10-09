variable "cluster_name" {
  type        = string
  description = "ECS cluster name."
}

variable "service_name" {
  type        = string
  description = "ECS service name."
}

variable "target_port" {
  type        = number
  description = "ECS port number."
}

variable "service_connect_namespace" {
  type        = string
  description = "Cloud Map namespace for Service Connect."
}

variable "cloud_map_service_id" {
  description = "The Cloud Map service ID for listing instances."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the Lambda VPC config"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for the Lambda VPC config"
  type        = list(string)
}

variable "lambda_code" {
  type        = string
  description = "Python code for the Lambda handler"
  default     = "" # Or set a default heredoc
}
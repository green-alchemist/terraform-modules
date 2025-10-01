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

# variable "api_gateway_arn" {
#   type        = string
#   description = "ARN of the API Gateway execution."
# }
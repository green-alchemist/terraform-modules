variable "cluster_name" {
  description = "The name of the ECS cluster."
  type        = string
}

variable "task_family" {
  description = "The family of the ECS task definition."
  type        = string
}

variable "service_name" {
  description = "The name of the ECS service."
  type        = string
}

variable "ecr_repository_url" {
  description = "The URL of the ECR repository."
  type        = string
}

variable "task_cpu" {
  description = "The number of CPU units used by the task."
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "The amount of memory (in MiB) used by the task."
  type        = number
  default     = 512
}

variable "container_port" {
  description = "The port on the container to expose."
  type        = number
  default     = 1337
}

variable "container_name" {
  description = "The name of the container."
  type        = string
}

variable "desired_count" {
  description = "The number of instances of the task to run."
  type        = number
  default     = 1
}

variable "ecs_task_execution_role_arn" {
  description = "The ARN of the IAM role that allows ECS tasks to make API calls."
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs to associate with the service."
  type        = list(string)
}

variable "security_group_ids" {
  description = "A list of security group IDs to associate with the service."
  type        = list(string)
}

variable "environment_variables" {
  description = "A map of environment variables to pass to the container."
  type        = map(string)
  default     = {}
}
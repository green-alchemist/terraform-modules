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
  default     = 1024
}

variable "task_memory" {
  description = "The amount of memory (in MiB) used by the task."
  type        = number
  default     = 2048
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

variable "task_role_arn" {
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

variable "load_balancers" {
  description = "A list of load balancer configurations to attach to the service."
  type = list(object({
    target_group_arn = string
    container_name   = string
    container_port   = number
  }))
  default = []
}

variable "enable_autoscaling" {
  description = "If true, enables auto-scaling for the Fargate service."
  type        = bool
  default     = false
}

variable "min_tasks" {
  description = "The minimum number of tasks for auto-scaling."
  type        = number
  default     = 0
}

variable "max_tasks" {
  description = "The maximum number of tasks for auto-scaling."
  type        = number
  default     = 1
}

variable "service_connect_enabled" {
  description = "If true, registers the service with AWS Cloud Map."
  type        = bool
  default     = false
}

# variable "service_connect_namespace_arn" {
#   description = "The ARN of the Service Connect namespace."
#   type        = string
#   default     = null
# }

variable "private_dns_namespace" {
  description = "The name of the private DNS namespace (e.g., 'internal')."
  type        = string
  default     = "internal"
}

variable "vpc_id" {
  description = "The ID of the VPC to deploy the service into."
  type        = string
}

variable "assign_public_ip" {
  description = "Whether to assign a public IP to the Fargate task."
  type        = bool
  default     = false
}

variable "aws_region" {
  description = "The AWS region where the resources are located."
  type        = string
  default     = "us-east-1"
}

variable "scale_down_period_seconds" {
  description = "The period in seconds over which to evaluate the scale-down metric."
  type        = number
  default     = 300 # 5 minutes
}

variable "scale_down_evaluation_periods" {
  description = "The number of consecutive periods the scale-down metric must be low to trigger an alarm."
  type        = number
  default     = 3 # 3 periods x 5 minutes = 15 minutes total
}

variable "cpu_utilization_high_threshold" {
  description = "The CPU utilization percentage to trigger a scale-up event."
  type        = number
  default     = 75
}

variable "cpu_utilization_low_threshold" {
  description = "The CPU utilization percentage to trigger a scale-down event. This should be low for scale-to-zero."
  type        = number
  default     = 20 # A low threshold to indicate idleness
}

variable "enable_execute_command" {
  description = "Specifies whether to enable Amazon ECS Exec for the tasks within the service."
  type        = bool
  default     = false
}

variable "service_discovery_health_check_enabled" {
  description = "If true, enables custom health checking for the AWS Cloud Map service. If false, Cloud Map will not perform health checks."
  type        = bool
  default     = false
}

variable "container_secrets" {
  description = "A map of secret environment variables to set. The key is the variable name, the value is the full ARN of the SSM Parameter Store parameter."
  type        = map(string)
  default     = {}
}

variable "health_check_enabled" {
  description = "Enable container health checks."
  type        = bool
  default     = true
}

variable "health_check_command" {
  description = "The command to run for the health check."
  type        = list(string)
  default     = ["CMD-SHELL", "curl -f http://localhost:1337/admin || exit 1"]
}

variable "health_check_interval" {
  description = "The time period in seconds between each health check."
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "The time period in seconds to wait for a health check to succeed before it is considered a failure."
  type        = number
  default     = 5
}

variable "health_check_retries" {
  description = "The number of consecutive failed health checks that must occur before a container is considered unhealthy."
  type        = number
  default     = 3
}

variable "health_check_start_period" {
  description = "The grace period in seconds during which failed health checks are ignored when a task has just started."
  type        = number
  default     = 0
}

variable "target_request_count" {
  type        = number
  default     = 10
  description = "Target average requests per second per task to trigger scaling."
}
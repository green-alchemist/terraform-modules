variable "service_name" {
  description = "Name of the service"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where Lambda will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for Lambda VPC configuration"
  type        = list(string)
}

variable "target_service_name" {
  description = "Name of the target service in Service Connect"
  type        = string
}

# Optional variables with defaults
variable "service_connect_namespace" {
  description = "Service Connect namespace"
  type        = string
  default     = "local"
}

variable "target_port" {
  description = "Port that the target service is running on"
  type        = number
  default     = 80
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "nodejs20.x"
}

variable "timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "Lambda memory size in MB"
  type        = number
  default     = 256
}

variable "reserved_concurrent_executions" {
  description = "Reserved concurrent executions for Lambda"
  type        = number
  default     = -1
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

variable "log_level" {
  description = "Logging level (ERROR, WARN, INFO, DEBUG)"
  type        = string
  default     = "INFO"
}

variable "kms_key_arn" {
  description = "KMS key ARN for log encryption"
  type        = string
  default     = null
}

variable "xray_tracing_enabled" {
  description = "Enable AWS X-Ray tracing"
  type        = bool
  default     = false
}

variable "enable_service_discovery_permissions" {
  description = "Enable IAM permissions for ECS Service Discovery"
  type        = bool
  default     = false
}

# Network configuration
variable "target_service_cidr_blocks" {
  description = "CIDR blocks that contain the target service"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

variable "additional_egress_rules" {
  description = "Additional egress rules for Lambda security group"
  type = map(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = optional(list(string))
    description = optional(string)
  }))
  default = {}
}

# API Gateway integration
variable "api_gateway_execution_arn" {
  description = "API Gateway execution ARN for Lambda permissions"
  type        = string
  default     = null
}

# Environment variables
variable "additional_environment_variables" {
  description = "Additional environment variables for Lambda"
  type        = map(string)
  default     = {}
}

# IAM policies
variable "additional_iam_policies" {
  description = "Additional IAM policies to attach to Lambda role"
  type        = map(string)
  default     = {}
}

# Lambda permissions
variable "lambda_permissions" {
  description = "Additional Lambda invoke permissions"
  type = map(object({
    principal  = string
    source_arn = optional(string)
  }))
  default = {}
}

# Custom Lambda code
variable "custom_lambda_code" {
  description = "Custom Lambda function code (overrides default proxy code)"
  type        = string
  default     = null
}

# Monitoring
variable "enable_monitoring" {
  description = "Enable CloudWatch alarms for Lambda"
  type        = bool
  default     = true
}

variable "error_threshold" {
  description = "Error count threshold for CloudWatch alarm"
  type        = number
  default     = 10
}

variable "throttle_threshold" {
  description = "Throttle count threshold for CloudWatch alarm"
  type        = number
  default     = 5
}

variable "alarm_actions" {
  description = "SNS topic ARNs for CloudWatch alarms"
  type        = list(string)
  default     = []
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
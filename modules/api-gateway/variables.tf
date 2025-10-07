variable "name" {
  description = "The name for the API Gateway and related resources."
  type        = string
}

variable "stage_name" {
  description = "The name of the deployment stage (e.g., '$default')."
  type        = string
  default     = "$default"
}

variable "domain_name" {
  description = "The custom domain name for the API Gateway."
  type        = string
}

variable "acm_certificate_arn" {
  description = "The ARN of the ACM certificate for the custom domain."
  type        = string
}

# --- Integration Variables ---

variable "integration_type" {
  description = "The integration type. Supported values: 'HTTP_PROXY' (for VPC Link), 'AWS_PROXY' (for Lambda)."
  type        = string
  validation {
    condition     = contains(["HTTP_PROXY", "AWS_PROXY"], var.integration_type)
    error_message = "The integration_type must be either 'HTTP_PROXY' or 'AWS_PROXY'."
  }
}

variable "integration_uri" {
  description = "The integration URI. For Lambda, this is the function's invoke ARN. For HTTP_PROXY, this is the target URI (e.g., Cloud Map service)."
  type        = string
}

variable "integration_method" {
  description = "The integration Method"
  type        = string
  default     = "ANY"
}

variable "route_keys" {
  description = "A list of route keys to create for the integration."
  type        = list(string)
  default     = ["ANY /{proxy+}"]
}

# --- VPC Link Specific Variables (only used if integration_type is 'HTTP_PROXY') ---

variable "subnet_ids" {
  description = "A list of subnet IDs for the VPC Link. Required for 'HTTP_PROXY' integration."
  type        = list(string)
  default     = []
}

variable "vpc_link_security_group_ids" {
  description = "A list of security group IDs for the VPC Link. Required for 'HTTP_PROXY' integration."
  type        = list(string)
  default     = []
}

variable "lambda_security_group_ids" {
  description = "A list of security group IDs for the Lambda. Required for 'HTTP_PROXY' integration."
  type        = list(string)
  default     = []
}

# --- Lambda Proxy Variables ---

variable "enable_lambda_proxy" {
  description = "Enable the nested Lambda proxy for scale-to-zero (overrides integration_type to 'AWS_PROXY')."
  type        = bool
  default     = false
}

variable "cluster_name" {
  description = "The ECS cluster name (for Lambda proxy scale-up)."
  type        = string
  default     = ""
}

variable "service_name" {
  description = "The ECS service name (for Lambda proxy scale-up)."
  type        = string
  default     = ""
}

variable "service_connect_namespace" {
  description = "The Cloud Map namespace for Service Connect (for Lambda proxy)."
  type        = string
  default     = ""
}

variable "cloud_map_service_id" {
  description = "The Cloud Map service ID for listing instances (for Lambda proxy)."
  type        = string
  default     = ""
}

variable "target_port" {
  description = "The target port for the ECS service (for Lambda proxy)."
  type        = number
  default     = 1337
}

# --- Logging Variables ---

variable "enable_access_logging" {
  description = "Set to true to enable access logging for the API Gateway stage."
  type        = bool
  default     = false
}

variable "log_retention_in_days" {
  description = "The number of days to retain the access logs."
  type        = number
  default     = 7
}

variable "throttling_burst_limit" {
  description = "The throttling burst limit for the API."
  type        = number
  default     = 10000
}

variable "throttling_rate_limit" {
  description = "The throttling rate limit for the API."
  type        = number
  default     = 5000
}

variable "integration_timeout_millis" {
  description = "The timeout in milliseconds for the API Gateway integration."
  type        = number
  default     = 60000
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default     = {}
}
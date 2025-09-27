variable "name" {
  description = "The name for the API Gateway and related resources."
  type        = string
}

variable "stage_name" {
  description = "The name of the deployment stage (e.g., 'staging')."
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

variable "route_keys" {
  description = "A list of route keys to create for the integration."
  type        = list(string)
  default     = ["$default"]
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

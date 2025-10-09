variable "state_machine_name" {
  description = "Name for the Step Function state machine."
  type        = string
}

variable "lambda_function_arn" {
  description = "ARN of the Lambda function to be invoked by the state machine."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default     = {}
}

variable "enable_logging" {
  description = "Set to true to enable CloudWatch logging for the state machine."
  type        = bool
  default     = true
}

variable "log_level" {
  description = "Determines the logging level for the state machine. Valid values: ALL, ERROR, FATAL, OFF."
  type        = string
  default     = "ALL"
}

variable "include_execution_data" {
  description = "Determines whether execution data is included in your log. When set to false, data is excluded."
  type        = bool
  default     = true
}

variable "definition" {
  type        = string
  default     = ""
  description = "Custom Step Function definition (JSON string). If empty, uses default definition."
}
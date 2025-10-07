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
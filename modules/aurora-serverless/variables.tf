variable "database_name" {
  description = "The name of the database to create."
  type        = string
}

variable "master_username" {
  description = "The username for the master database user."
  type        = string
}

variable "master_password" {
  description = "The password for the master database user."
  type        = string
  sensitive   = true
}

variable "subnet_ids" {
  description = "A list of subnet IDs to associate with the database."
  type        = list(string)
}

variable "security_group_ids" {
  description = "A list of security group IDs to associate with the database."
  type        = list(string)
}

variable "min_capacity" {
  description = "The minimum capacity for the Aurora Serverless v1 cluster."
  type        = number
  default     = 0.0
}

variable "max_capacity" {
  description = "The maximum capacity for the Aurora Serverless v1 cluster."
  type        = number
  default     = 1.0
}

variable "seconds_until_auto_pause" {
  description = "The time, in seconds, before an idle cluster is paused."
  type        = number
  default     = 600
}

variable "enabled_cloudwatch_logs_exports" {
  description = "A list of log types to export to CloudWatch Logs. For PostgreSQL, common values are 'postgresql' and 'upgrade'."
  type        = list(string)
  default     = ["postgresql"]
}

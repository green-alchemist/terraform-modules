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
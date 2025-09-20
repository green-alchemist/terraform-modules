variable "zone_id" {
  description = "The ID of the Route 53 hosted zone where the records will be created."
  type        = string
}

variable "domain_name" {
  description = "The apex domain name (e.g., kconley.com)."
  type        = string
}

variable "record_names" {
  description = "A list of record names to create. Use '@' for the apex domain."
  type        = list(string)
  default     = ["@", "www"]
}

variable "alias_zone_id" {
  description = "The hosted zone ID of the target resource (e.g., the CloudFront distribution's hosted zone ID)."
  type        = string
}


variable "alias_target_domain_name" {
  description = "The target domain name for the alias record."
  type        = string
  default     = ""
}
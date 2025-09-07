variable "domain_name" {
  description = "The domain name for which to create the hosted zone (e.g., kconley.com)."
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to the hosted zone."
  type        = map(string)
  default     = {}
}

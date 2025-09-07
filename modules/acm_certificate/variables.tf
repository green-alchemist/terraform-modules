variable "domain_name" {
  description = "The primary domain name for the certificate."
  type        = string
}

variable "subject_alternative_names" {
  description = "A list of additional domain names to be included in the certificate."
  type        = list(string)
  default     = []
}

variable "route53_zone_id" {
  description = "The ID of the Route 53 hosted zone to use for DNS validation."
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to the certificate."
  type        = map(string)
  default     = {}
}

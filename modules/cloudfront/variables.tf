variable "domain_name" {
  description = "The primary custom domain name for the website (e.g., kconley.com)."
  type        = string
}

variable "domain_aliases" {
  description = "A list of alternate domain names (CNAMEs) for the distribution."
  type        = list(string)
  default     = []
}

variable "s3_origin_domain_name" {
  description = "The S3 bucket website endpoint."
  type        = string
}

variable "s3_origin_id" {
  description = "The S3 bucket ID, to be used as the CloudFront origin ID."
  type        = string
}

variable "acm_certificate_arn" {
  description = "The ARN of the ACM SSL certificate."
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to resources."
  type        = map(string)
  default     = {}
}

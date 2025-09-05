variable "domain_name" {
  description = "The custom domain name for the website (e.g., kconley.com)."
  type        = string
}

variable "s3_origin_domain_name" {
  description = "The S3 bucket website endpoint."
  type        = string
}

variable "s3_origin_id" {
  description = "The S3 bucket ID, to be used as the CloudFront origin ID."
  type        = string
}

variable "route53_zone_id" {
  description = "The ID of the Route 53 hosted zone for the domain."
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

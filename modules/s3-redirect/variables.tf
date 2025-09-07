variable "bucket_name" {
  description = "The source domain name that will be redirected (e.g., kconley.com)."
  type        = string
}

variable "redirect_hostname" {
  description = "The target hostname to which requests will be redirected (e.g., portfolio.kconley.com)."
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to the bucket."
  type        = map(string)
  default     = {}
}

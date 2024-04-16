variable "tags" {
  description = "A mapping of tags to assign to all resources"
  type        = map(string)
  default     = {}
}
## tags example
# tags = {
#   Terraform = "true"
# }

variable "ecrs" {
  description = "Map of ECRs to create."
  type        = any
  default     = {}
}
## ercs example
# ecrs = {
#   strapi-admin-dev = {
#     tags = { Service = "strapi-admin-dev", Env = "dev" }
#     lifecycle_policy = local.lifecycle_policy # use if overriding default policy
#   },
#   strapi-admin-prod = {
#     tags = { Service = "strapi-admin-prod", Env = "prod" }
#   }
# }
  
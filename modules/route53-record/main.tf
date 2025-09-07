# Creates one or more Route 53 alias records based on the provided list of names.
resource "aws_route53_record" "this" {
  # Iterates over the set of record names to create a record for each.
  for_each = toset(var.record_names)

  zone_id = var.zone_id
  # If the name is "@", use the apex domain name. Otherwise, create a subdomain.
  name    = each.value == "@" ? var.domain_name : "${each.value}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alias_name
    zone_id                = var.alias_zone_id
    evaluate_target_health = false
  }
}

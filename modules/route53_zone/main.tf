# Creates a public Route 53 hosted zone for managing DNS records for a domain.
resource "aws_route53_zone" "this" {
  name = var.domain_name

  tags = var.tags
}

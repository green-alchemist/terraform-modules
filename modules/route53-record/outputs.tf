output "fqdns" {
  description = "A map of the created records and their fully qualified domain names."
  value       = { for key, record in aws_route53_record.this : key => record.fqdn }
}
output "subnet_ids" {
  description = "A list of the created subnet IDs."
  value       = [for s in aws_subnet.this : s.id]
}

output "subnet_ids_map" {
  description = "A map of the created subnet IDs, keyed by Availability Zone."
  value       = { for az, subnet in aws_subnet.this : az => subnet.id }
}

output "subnet_objects" {
  description = "A map of the created subnet objects, keyed by Availability Zone."
  value       = aws_subnet.this
}
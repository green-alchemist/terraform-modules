output "subnet_ids_map" {
  description = "A map of the public subnet IDs, keyed by Availability Zone."
  value       = { for az, subnet in aws_subnet.public_subnet : az => subnet.id }
}

output "subnet_ids" {
  description = "A list of the public subnet IDs."
  value       = [for s in aws_subnet.public_subnet : s.id]
}

output "public_subnets_map" {
  description = "A map of the created public subnet objects."
  value       = aws_subnet.public_subnet
}
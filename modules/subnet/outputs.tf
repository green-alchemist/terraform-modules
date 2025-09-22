output "subnet_ids" {
  description = "A list of the private subnet IDs."
  value       = [for s in aws_subnet.private_subnet : s.id]
}

output "private_subnets_map" {
  description = "A map of the created private subnet objects."
  value       = aws_subnet.private_subnet
}
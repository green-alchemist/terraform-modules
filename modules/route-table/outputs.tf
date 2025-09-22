output "public_route_table_id" {
  description = "The ID of the public Route Table."
  value       = one(aws_route_table.public[*].id)
}

output "private_route_table_id" {
  description = "The ID of the private Route Table."
  value       = one(aws_route_table.private[*].id)
}
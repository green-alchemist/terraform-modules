output "id" {
  description = "The ID of the NAT Gateway."
  value       = aws_nat_gateway.this[0].id
}
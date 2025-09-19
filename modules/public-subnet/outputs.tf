output "subnet_ids_map" {
  description = "A map of the public subnet IDs, keyed by Availability Zone."
  value       = { for az, subnet in aws_subnet.public_subnet : az => subnet.id }
}

output "subnet_ids" {
  description = "A list of the public subnet IDs."
  value       = values(aws_subnet.public_subnet)[*].id
}

output "public_subnet_arn" {
  description = "The ARN of the Public Subnet"
  value       = concat(aws_subnet.public_subnet.*.arn, [""])[0]
}
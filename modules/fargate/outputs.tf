output "service_name" {
  description = "The name of the ECS service."
  value       = aws_ecs_service.this.name
}

output "cluster_name" {
  description = "The name of the ECS cluster."
  value       = aws_ecs_cluster.this.name
}

output "service_discovery_dns_name" {
  description = "The private DNS name of the service."
  value       = var.service_connect_enabled ? "${var.service_name}.${var.private_dns_namespace}" : ""
}

output "service_discovery_namespace" {
  value       = aws_service_discovery_private_dns_namespace.this[0].name
  description = "Cloud Map namespace for Service Connect."
}

output "service_discovery_arn" {
  description = "The ARN of the Service Discovery service, for use in API Gateway integrations."
  value       = one(aws_service_discovery_service.this[*].arn)
}

output "service_arn" {
  description = "The ARN of the ECS service."
  value       = aws_ecs_service.this.id
}

output "container_port" {
  description = "The port exposed by the container."
  value       = var.container_port
}
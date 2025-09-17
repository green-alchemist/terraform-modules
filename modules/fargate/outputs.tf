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
  value       = var.enable_service_discovery ? "${var.service_name}.${var.private_dns_namespace}" : ""
}
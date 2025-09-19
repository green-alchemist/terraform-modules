output "cluster_endpoint" {
  description = "The endpoint of the RDS cluster."
  value       = aws_rds_cluster.this.endpoint
}

output "cluster_port" {
  description = "The port of the RDS cluster."
  value       = aws_rds_cluster.this.port
}

output "database_name" {
  description = "The name of the database."
  value       = aws_rds_cluster.this.database_name
}

output "master_username" {
  description = "The master_username of the database."
  value       = aws_rds_cluster.this.master_username
}
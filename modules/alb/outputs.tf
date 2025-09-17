output "target_group_arn" {
  description = "The ARN of the target group."
  value       = aws_lb_target_group.this.arn
}

output "dns_name" {
  description = "The DNS name of the load balancer."
  value       = aws_lb.this.dns_name
}

output "zone_id" {
  description = "The zone ID of the load balancer."
  value       = aws_lb.this.zone_id
}
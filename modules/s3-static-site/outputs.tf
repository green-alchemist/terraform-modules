output "bucket_id" {
  description = "The name of the S3 bucket."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket."
  value       = aws_s3_bucket.this.arn
}

output "website_endpoint" {
  description = "The website endpoint of the S3 bucket."
  value       = aws_s3_bucket_website_configuration.this.website_endpoint
}

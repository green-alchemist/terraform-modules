output "website_endpoint" {
  description = "The website endpoint of the S3 redirect bucket."
  value       = aws_s3_bucket_website_configuration.this.website_endpoint
}

output "hosted_zone_id" {
  description = "The Route 53 hosted zone ID for the S3 bucket's website endpoint."
  value       = aws_s3_bucket.this.hosted_zone_id
}

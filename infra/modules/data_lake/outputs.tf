output "bucket_id" {
  description = "Name of the data lake bucket"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN of the data lake bucket"
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "Bucket domain name (for use as a Lambda destination, etc.)"
  value       = aws_s3_bucket.this.bucket_domain_name
}

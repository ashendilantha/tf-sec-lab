output "vpc_id" {
  description = "ID of the lab VPC"
  value       = aws_vpc.lab.id
}

output "security_group_id" {
  description = "ID of the lab security group"
  value       = aws_security_group.lab.id
}

output "s3_bucket_name" {
  description = "Name of the lab S3 bucket"
  value       = aws_s3_bucket.storage.bucket
}

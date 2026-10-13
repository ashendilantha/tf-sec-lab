resource "aws_vpc" "lab" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-vps"
    Environment = "lab"
  }
}

resource "aws_security_group" "lab" {
  name        = "${var.project_name}-sg"
  description = "Default-deny network access for the lab"
  vpc_id      = aws_vpc.lab.id

  tags = {
    Name        = "${var.project_name}-sg"
    Environment = "lab"
  }
}

resource "aws_s3_bucket" "storage" {
  bucket = var.bucket_name

  tags = {
    Name        = "${var.project_name}-storage"
    Environment = "lab"
  }
}

resource "aws_s3_bucket_public_access_block" "storage" {
  bucket = aws_s3_bucket.storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "storage" {
  bucket = aws_s3_bucket.storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "storage" {
  bucket = aws_s3_bucket.storage.id

  versioning_configuration {
    status = "Enabled"
  }
}

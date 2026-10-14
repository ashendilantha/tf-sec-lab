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

resource "aws_s3_bucket_notification" "storage" {
  bucket      = aws_s3_bucket.storage.id
  eventbridge = true
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
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "storage" {
  bucket = aws_s3_bucket.storage.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_default_security_group" "lab" {
  vpc_id = aws_vpc.lab.id

  ingress = []
  egress  = []

  tags = {
    Name        = "${var.project_name}-default-sg"
    Environment = "lab"
  }
}


resource "aws_s3_bucket_lifecycle_configuration" "storage" {
  bucket = aws_s3_bucket.storage.id

  rule {
    id     = "abort-incomplete-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_logging" "storage" {
  bucket        = aws_s3_bucket.storage.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "storage-logs/"
}

resource "aws_flow_log" "lab" {
  log_destination      = aws_s3_bucket.logs.arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.lab.id

  tags = {
    Name        = "${var.project_name}-flow-log"
    Environment = "lab"
  }
}

resource "aws_s3_bucket" "logs" {
  bucket = "${var.bucket_name}-logs"

  tags = {
    Name        = "${var.project_name}-logs"
    Environment = "lab"
  }
}

resource "aws_s3_bucket_notification" "logs" {
  bucket      = aws_s3_bucket.logs.id
  eventbridge = true
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "abort-incomplete-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_subnet" "lab" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.10.1.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.project_name}-subnet"
    Environment = "lab"
  }
}

resource "aws_network_interface" "lab" {
  subnet_id       = aws_subnet.lab.id
  security_groups = [aws_security_group.lab.id]

  tags = {
    Name        = "${var.project_name}-nic"
    Environment = "lab"
  }
}

resource "aws_iam_role" "replication" {
  name        = "${var.project_name}-s3-replication-role"
  description = "IAM role for S3 bucket replication"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-s3-replication-role"
    Environment = "lab"
  }
}

resource "aws_s3_bucket_replication_configuration" "storage" {
  depends_on = [aws_s3_bucket_versioning.storage]
  role       = aws_iam_role.replication.arn
  bucket     = aws_s3_bucket.storage.id

  rule {
    id     = "replicate-all"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.logs.arn
      storage_class = "STANDARD"
    }
  }
}

resource "aws_s3_bucket_replication_configuration" "logs" {
  depends_on = [aws_s3_bucket_versioning.logs]
  role       = aws_iam_role.replication.arn
  bucket     = aws_s3_bucket.logs.id

  rule {
    id     = "replicate-logs"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.storage.arn
      storage_class = "STANDARD"
    }
  }
}


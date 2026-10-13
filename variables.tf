variable "aws_region" {
  description = "AWS region for the lab"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Name used to tag resource"
  type        = string
  default     = "terraform-security-starter"
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name if deployed"
  type        = string
  default     = "terraform-security-starter-change-me"
}

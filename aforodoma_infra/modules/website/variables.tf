variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
  default     = "aforodoma-site"
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {
    Environment = "dev"
    Project     = "portfolio"
  }
}

variable "acm_certificate_arn" {
  description = "The ACM cert ARN for CloudFront"
  type        = string
}

variable "environment" {
  description = "The environment name (e.g., dev, prod)"
  type        = string
}

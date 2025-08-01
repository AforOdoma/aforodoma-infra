#####################
# S3 Bucket
#####################
# S3 Bucket
resource "aws_s3_bucket" "main" {
  bucket = "${var.environment}-${var.bucket_name}"
  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-${var.bucket_name}"
    },
  )
}

resource "aws_s3_bucket_ownership_controls" "main" {
  bucket = aws_s3_bucket.main.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}



resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = false  # Changed from true to false
  ignore_public_acls      = true
  restrict_public_buckets = false  # Changed from true to false
}




resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowCloudFrontAccess",
        Effect = "Allow",
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.main.iam_arn
        },
        Action   = "s3:GetObject",
        Resource = "${aws_s3_bucket.main.arn}/*"
      }
    ]
  })
  
  depends_on = [aws_s3_bucket_public_access_block.main]
}





#####################
# CloudFront Distribution
#####################
resource "aws_cloudfront_origin_access_identity" "main" {
  comment = "OAI for aforodoma.com portfolio S3 bucket"
}

resource "aws_cloudfront_distribution" "main" {
  aliases = ["www.aforodoma.com", "aforodoma.com"]

  default_root_object = "index.html"
  
  origin {
    domain_name = aws_s3_bucket.main.bucket_regional_domain_name
    origin_id   = "S3-${var.bucket_name}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.main.cloudfront_access_identity_path
    }
  }

  enabled         = true
  is_ipv6_enabled = true
  price_class     = "PriceClass_100" # Use only North America and Europe edge locations
  # Use CloudFront domain name or configure your own domain/certificate

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${var.bucket_name}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }



    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  viewer_certificate {
  acm_certificate_arn            = var.acm_certificate_arn
  ssl_support_method             = "sni-only"
  minimum_protocol_version       = "TLSv1.2_2021"
}



  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = var.tags
}

resource "aws_s3_bucket_cors_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = [
  "https://www.aforodoma.com",
  "https://aforodoma.com"
]
    expose_headers = ["ETag", "x-amz-meta-custom-header"]
    max_age_seconds = 3000
  }
}


########################################
# S3 Bucket for Static Website
########################################

resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend-${random_id.bucket_suffix.hex}"

  tags = {
    Project = var.project_name
    Service = "frontend"
  }
}

# Random suffix to ensure unique bucket name
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Enable static website hosting
resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# Public access block configuration (allow public access)
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket policy to allow CloudFront access
resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.frontend]
}

########################################
# CloudFront Distribution
########################################

resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"  # Use only North America and Europe edge locations (cheapest)

  origin {
    domain_name = aws_s3_bucket_website_configuration.frontend.website_endpoint
    origin_id   = "S3-${aws_s3_bucket.frontend.id}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.frontend.id}"

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
    compress               = true
  }

  # Custom error response for SPA routing
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Project = var.project_name
    Service = "frontend"
  }
}

########################################
# Upload Frontend Files to S3
########################################

# Upload HTML files
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "index.html"
  source       = "../frontend/index.html"
  etag         = filemd5("../frontend/index.html")
  content_type = "text/html"
}

resource "aws_s3_object" "signup_html" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "signup.html"
  source       = "../frontend/signup.html"
  etag         = filemd5("../frontend/signup.html")
  content_type = "text/html"
}

resource "aws_s3_object" "login_html" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "login.html"
  source       = "../frontend/login.html"
  etag         = filemd5("../frontend/login.html")
  content_type = "text/html"
}

resource "aws_s3_object" "dashboard_html" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "dashboard.html"
  source       = "../frontend/dashboard.html"
  etag         = filemd5("../frontend/dashboard.html")
  content_type = "text/html"
}

# Upload CSS
resource "aws_s3_object" "style_css" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "css/style.css"
  source       = "../frontend/css/style.css"
  etag         = filemd5("../frontend/css/style.css")
  content_type = "text/css"
}

# Upload JavaScript files
resource "aws_s3_object" "auth_js" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "js/auth.js"
  source       = "../frontend/js/auth.js"
  etag         = filemd5("../frontend/js/auth.js")
  content_type = "application/javascript"
}

resource "aws_s3_object" "events_js" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "js/events.js"
  source       = "../frontend/js/events.js"
  etag         = filemd5("../frontend/js/events.js")
  content_type = "application/javascript"
}

# Upload config.json
resource "aws_s3_object" "config_json" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "config.json"
  content      = jsonencode({
    auth_base   = "${aws_api_gateway_stage.auth_stage.invoke_url}/auth"
    events_base = "${aws_api_gateway_stage.auth_stage.invoke_url}/events"
  })
  content_type = "application/json"
  etag         = md5(jsonencode({
    auth_base   = "${aws_api_gateway_stage.auth_stage.invoke_url}/auth"
    events_base = "${aws_api_gateway_stage.auth_stage.invoke_url}/events"
  }))
}

########################################
# Outputs
########################################

output "s3_bucket_name" {
  value       = aws_s3_bucket.frontend.id
  description = "Name of S3 bucket hosting frontend"
}

output "s3_website_endpoint" {
  value       = aws_s3_bucket_website_configuration.frontend.website_endpoint
  description = "S3 website endpoint"
}

output "cloudfront_url" {
  value       = "https://${aws_cloudfront_distribution.frontend.domain_name}"
  description = "CloudFront distribution URL (your public frontend URL)"
}

output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.frontend.id
  description = "CloudFront distribution ID"
}
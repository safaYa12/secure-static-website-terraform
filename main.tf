locals {
  bucket_name = "${var.bucket_name_prefix}-${var.environment}"

  content_type = {
    html = "text/html"
    css  = "text/css"
    js   = "application/javascript"
    json = "application/json"
    png  = "image/png"
    jpg  = "image/jpeg"
    svg  = "image/svg+xml"
    ico  = "image/x-icon"
  }

  common_tags = {
    Environment = var.environment
    Project     = "Secure_Static_Website"
    ManagedBy   = "Terraform"
  }
}

# Create S3 bucket for static website
resource "aws_s3_bucket" "website" {
  bucket = local.bucket_name

  tags = local.common_tags
}

# Block all public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront OAC
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.environment}-oac"
  description                       = "Origin Access Control for CloudFront to access S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Upload static website content to S3 bucket
resource "aws_s3_object" "website_files" {
  for_each = fileset("${path.module}/www", "**/*")

  bucket = aws_s3_bucket.website.id

  key    = each.value
  source = "${path.module}/www/${each.value}"
  etag   = filemd5("${path.module}/www/${each.value}")

  content_type = lookup(
    local.content_type,
    lower(element(reverse(split(".", each.value)), 0)),
    "application/octet-stream"
  )

}

# S3 bucket policy to allow CloudFront access
resource "aws_s3_bucket_policy" "cloudfront_access" {
  bucket = aws_s3_bucket.website.id
  depends_on = [
    aws_s3_bucket_public_access_block.website
  ]
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.website.arn
          }
        }
      }
    ]
  })
}

resource "aws_cloudfront_response_headers_policy" "security" {
  name = "${var.environment}-security-headers-policy"
  security_headers_config {

    # Prevent MIME sniffing
    content_type_options {
      override = true
    }
    # Prevent clickjacking
    frame_options {
      override     = true
      frame_option = "DENY"
    }
    # Control referrer information
    referrer_policy {
      override        = true
      referrer_policy = "strict-origin-when-cross-origin"
    }
    # Enforce HTTPS for future requests
    strict_transport_security {
      override                   = true
      access_control_max_age_sec = 31536000
      include_subdomains         = false
      preload                    = false
    }
  }

  custom_headers_config {
    items {
      header   = "Permissions-Policy"
      value    = "camera=(), microphone=(), geolocation=()"
      override = true
    }
    items {
      header   = "X-Permitted-Cross-Domain-Policies"
      value    = "none"
      override = true
    }
  }
}

resource "aws_cloudfront_distribution" "website" {

  enabled         = true
  is_ipv6_enabled = true

  comment = "${var.environment} secure website"

  default_root_object = "index.html"

  # Attach WAF only when enabled
  web_acl_id = var.enable_waf ? aws_wafv2_web_acl.website[0].arn : null

  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name

    origin_id = "private-s3-origin"

    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {

    target_origin_id = "private-s3-origin"

    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]

    cached_methods = ["GET", "HEAD"]

    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"

    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id
  }

  price_class = "PriceClass_100"

  # Custom error pages
  custom_error_response {
    error_code            = 403
    response_page_path    = "/404.html"
    response_code         = 404
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_page_path    = "/404.html"
    response_code         = 404
    error_caching_min_ttl = 10
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = local.common_tags
}

resource "aws_wafv2_web_acl" "website" {
  provider = aws.use1
  count    = var.enable_waf ? 1 : 0

  name        = "${var.environment}-waf"
  description = "WAF for CloudFront distribution"
  scope       = "CLOUDFRONT"


  default_action {
    allow {}
  }

  # Common managed rule group
  rule {
    name     = "AWS-Common-Rule-Set"
    priority = 1

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # Rate-based protection
  rule {
    name     = "Rate-Limit"
    priority = 2

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit                 = var.rate_limit
        aggregate_key_type    = "IP"
        evaluation_window_sec = 300
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "WebsiteWAF"
    sampled_requests_enabled   = true
  }
}



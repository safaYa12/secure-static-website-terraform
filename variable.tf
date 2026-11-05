variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-2"
}

variable "bucket_name_prefix" {
  description = "Unique prefix for the S3 bucket name"
  type        = string
}
variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "enable_waf" {
  description = "Enable AWS WAF for CloudFront distribution"
  type        = bool
  default     = false

}

variable "rate_limit" {
  description = "Rate limit for WAF (requests per 5 minutes)"
  type        = number
  default     = 2000
}


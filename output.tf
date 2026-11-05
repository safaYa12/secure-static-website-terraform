output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.website.id
}

output "website_url" {
  value = "https://${aws_cloudfront_distribution.website.domain_name}"
}

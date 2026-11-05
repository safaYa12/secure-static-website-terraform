terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
# Configure the AWS Provider
provider "aws" {
  region = "ap-southeast-2"
}

# CloudFront WAF resources must use us-east-1
provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}


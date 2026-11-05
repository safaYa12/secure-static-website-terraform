# Secure AWS Static Website with Terraform

A security-focused static website hosted on **Amazon S3 and Amazon CloudFront**, provisioned using **Terraform** and protected with **AWS Web Application Firewall (WAF)**.

This project demonstrates how to deploy a static website using AWS infrastructure while applying security best practices such as private S3 storage, CloudFront Origin Access Control (OAC), HTTPS enforcement, security response headers, and web application firewall protection.

## Architecture

```text
                 Internet Users
                       |
                       | HTTPS
                       v
              Amazon CloudFront
                       |
                       | AWS WAF
                       |
                       | Origin Access Control
                       | (SigV4 Signing)
                       v
                Private Amazon S3
                 Static Website
```

CloudFront acts as the public entry point for the website. The S3 bucket remains private and accepts content requests through CloudFront using Origin Access Control.

## Project Objectives

- Deploy a static website using Amazon S3.
- Keep the S3 bucket private and prevent direct public access.
- Configure CloudFront Origin Access Control (OAC).
- Enforce HTTPS for website visitors.
- Implement HTTP security response headers.
- Protect the website using AWS WAF.
- Provision and manage infrastructure using Terraform.
- Test WAF protection against simulated malicious requests.

## AWS Services Used

| Service | Purpose |
|---|---|
| Amazon S3 | Private static website content storage |
| Amazon CloudFront | Content delivery and HTTPS access |
| CloudFront OAC | Secure access from CloudFront to S3 |
| AWS WAF | Web application protection |
| AWS IAM | Resource access permissions |
| Terraform | Infrastructure as Code |

## Security Implementations

### 1. Private Amazon S3 Bucket

- Created an S3 bucket for hosting website files.
- Enabled S3 Block Public Access.
- Prevented direct public access to bucket objects.
- Configured the bucket policy to allow `s3:GetObject` only from the designated CloudFront distribution.

### 2. CloudFront Origin Access Control (OAC)

Configured CloudFront Origin Access Control with:

- Origin type: S3
- Signing behavior: Always
- Signing protocol: SigV4

The S3 bucket policy restricts access to the CloudFront service principal and uses the distribution's AWS Source ARN to limit access to the intended distribution.

### 3. HTTPS Enforcement

Configured CloudFront Viewer Protocol Policy to redirect HTTP requests to HTTPS.

This ensures that visitors access the website over an encrypted connection.

### 4. Security Response Headers

Configured security-related HTTP response headers through CloudFront, including:

- Strict-Transport-Security (HSTS)
- X-Content-Type-Options
- X-Frame-Options
- Referrer-Policy
- Content-Security-Policy

These headers help mitigate common browser-based security risks.

### 5. Custom Error Page

Implemented a custom `404.html` page for handling unavailable website resources through CloudFront custom error responses.

### 6. AWS WAF Protection

Associated an AWS WAF Web ACL with the CloudFront distribution.

The protection configuration includes:

- AWS Managed Common Rule Set
- AWS Managed SQL Injection Rule Set
- AWS Managed Known Bad Inputs Rule Set
- Custom rate-based rule to restrict excessive requests

The managed SQL Injection and Known Bad Inputs rule groups were added through the AWS Console. The Terraform configuration should be kept synchronized with these console changes to ensure the complete WAF configuration is reproducible through Infrastructure as Code.

**WAF testing:** Simulated malicious requests and verified that AWS WAF protection was working as expected.

> Note: AWS WAF is a paid service. Review AWS pricing before reproducing this project in your own account.

## Terraform Infrastructure

The project uses Terraform to define and provision the AWS infrastructure.

Key Terraform configuration files:

| File | Description |
|---|---|
| `main.tf` | Main AWS resource definitions |
| `provider.tf` | AWS provider configuration |
| `variable.tf` | Input variable definitions |
| `output.tf` | Infrastructure outputs |
| `.terraform.lock.hcl` | Provider dependency lock file |
| `environments/` | Environment-specific variable files |
| `www/` | Static website files |

## Project Structure

```text
day-14-s3/
│
├── environments/
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
│
├── www/
│   ├── index.html
│   ├── 404.html
│   ├── style.css
│   └── script.js
│
├── .gitignore
├── .terraform.lock.hcl
├── main.tf
├── provider.tf
├── variable.tf
├── output.tf
└── README.md
```

Terraform state files, local Terraform working directories, plan files, and environment-specific variable files are excluded from Git.

## Deployment

### Prerequisites

- An AWS account with the required permissions.
- Terraform installed.
- AWS CLI installed and configured.
- Git installed.

### 1. Clone the Repository

```bash
git clone https://github.com/safaYa12/secure-static-website-terraform.git
cd secure-static-website-terraform
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Validate the Configuration

```bash
terraform validate
```

### 4. Review the Execution Plan

```bash
terraform plan -var-file="environments/dev.tfvars"
```

### 5. Apply the Configuration

```bash
terraform apply -var-file="environments/dev.tfvars"
```

Review the plan and confirm the changes before applying them.

### 6. Access the Website

After successful deployment, retrieve the CloudFront website URL from the Terraform outputs:

```bash
terraform output
```

Open the CloudFront URL in your browser.

## CI/CD Scope

GitHub Actions deployment using AWS IAM OpenID Connect (OIDC) was explored during development but was removed from the final implementation.

The AWS account is subject to an AWS Organizations Service Control Policy (SCP) that explicitly denies creation of the required IAM OIDC provider. Therefore, automated GitHub Actions deployment was not included in the final project.

The current implementation focuses on Terraform-based infrastructure provisioning.

## Monitoring Scope

CloudWatch dashboards, alarms, and WAF logging were considered but intentionally excluded from the current implementation to keep the project focused on infrastructure security and WAF protection.

## Important Notes

- The S3 bucket is private; the website is served through CloudFront.
- CloudFront uses OAC to securely access the S3 origin.
- The WAF managed SQL Injection and Known Bad Inputs rules were configured through the AWS Console and should be incorporated into Terraform for complete configuration reproducibility.
- Environment-specific `.tfvars` files and Terraform state files are not committed to the repository.
- Review AWS resource pricing before deploying. CloudFront, S3 requests, and AWS WAF may incur charges.
- This repository is intended for learning and demonstration. Review permissions, configurations, and costs before using it in production.

## Learning Outcomes

Through this project, I gained practical experience with:

- AWS infrastructure provisioning using Terraform.
- S3 bucket security and access control.
- CloudFront distribution configuration.
- Origin Access Control and SigV4 authentication.
- AWS WAF managed rule groups and rate-based protection.
- HTTP security response headers.
- Troubleshooting AWS permissions and Organizations SCP restrictions.
- Testing web application firewall protection.

## Repository

GitHub: https://github.com/safaYa12/secure-static-website-terraform

---

**Built as a hands-on AWS Cloud Security and Infrastructure as Code project.**

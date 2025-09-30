# Terraform AWS Modules

This repository contains a collection of reusable, production-ready Terraform modules for provisioning infrastructure on Amazon Web Services (AWS). Each module is designed to be a focused, configurable, and self-contained unit of infrastructure.

The primary goal of this repository is to enforce consistency, follow best practices, and accelerate the process of building new services.

## Available Modules

Below is a list of the modules available in this repository. For detailed information on the inputs, outputs, and usage of a specific module, please refer to the `README.md` file within its directory.
* [`acm_certificate`](./modules/acm_certificate/README.md)
* [`alb`](./modules/alb/README.md)
* [`api-gateway`](./modules/api-gateway/README.md)
* [`aurora-serverless`](./modules/aurora-serverless/README.md)
* [`bastion-host`](./modules/bastion-host/README.md)
* [`cloudfront`](./modules/cloudfront/README.md)
* [`ec2`](./modules/ec2/README.md)
* [`ecr`](./modules/ecr/README.md)
* [`ecs-task-execution-role`](./modules/ecs-task-execution-role/README.md)
* [`fargate`](./modules/fargate/README.md)
* [`internet-gateway`](./modules/internet-gateway/README.md)
* [`lambda-proxy`](./modules/lambda-proxy/README.md)
* [`nat-gateway`](./modules/nat-gateway/README.md)
* [`remote-state`](./modules/remote-state/README.md)
* [`route-tables`](./modules/route-tables/README.md)
* [`route53-record`](./modules/route53-record/README.md)
* [`route53-zone`](./modules/route53-zone/README.md)
* [`s3-redirect`](./modules/s3-redirect/README.md)
* [`s3-static-site`](./modules/s3-static-site/README.md)
* [`security-group`](./modules/security-group/README.md)
* [`ssm-parameter`](./modules/ssm-parameter/README.md)
* [`subnets`](./modules/subnets/README.md)
* [`vpc`](./modules/vpc/README.md)

## Usage

These modules are intended to be consumed by other Terraform projects (like a services repository). You can use them by referencing their path directly in your service's Terraform code.

### Example: Creating a Static Website

```hcl
# In a service's main.tf file

# 1. Look up the existing DNS zone
data "aws_route53_zone" "this" {
  name = "example.com"
}

# 2. Provision the S3 bucket for the site content
module "s3_site" {
  source      = "../../terraform-modules/modules/s3-static-site"
  bucket_name = "www.example.com"
  tags        = { Environment = "production" }
}

# 3. Provision the CloudFront distribution
module "cloudfront" {
  source                  = "../../terraform-modules/modules/cloudfront"
  s3_origin_domain_name   = module.s3_site.website_endpoint
  s3_origin_id            = module.s3_site.bucket_id
  domain_name             = "example.com"
  acm_certificate_arn     = "arn:aws:acm:us-east-1:123456789012:certificate/your-cert-id"
}

# 4. Create the DNS records
module "dns_records" {
  source        = "../../terraform-modules/modules/route53-record"
  zone_id       = data.aws_route53_zone.this.zone_id
  domain_name   = "example.com"
  record_names  = ["@", "www"]
  
  alias_name    = module.cloudfront.domain_name
  alias_zone_id = module.cloudfront.hosted_zone_id
}
```

## Development and Maintenance

This repository uses [Task](https://taskfile.dev/) for automation and quality control. The following commands are available for module development:

* `task fmt`: Formats all Terraform code in the repository.
* `task validate-all`: Initializes and validates every module to ensure its syntax is correct.
* `task docs`: Automatically generates or updates the `README.md` for all modules using `terraform-docs`.

To see a full list of available commands, run `task --list-all`.

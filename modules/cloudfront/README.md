## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.12.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudfront_distribution.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acm_certificate_arn"></a> [acm\_certificate\_arn](#input\_acm\_certificate\_arn) | The ARN of the ACM SSL certificate. | `string` | n/a | yes |
| <a name="input_domain_aliases"></a> [domain\_aliases](#input\_domain\_aliases) | A list of alternate domain names (CNAMEs) for the distribution. | `list(string)` | `[]` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | The primary custom domain name for the website (e.g., kconley.com). | `string` | n/a | yes |
| <a name="input_s3_origin_domain_name"></a> [s3\_origin\_domain\_name](#input\_s3\_origin\_domain\_name) | The S3 bucket website endpoint. | `string` | n/a | yes |
| <a name="input_s3_origin_id"></a> [s3\_origin\_id](#input\_s3\_origin\_id) | The S3 bucket ID, to be used as the CloudFront origin ID. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to apply to resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_domain_name"></a> [domain\_name](#output\_domain\_name) | The domain name of the CloudFront distribution. |
| <a name="output_hosted_zone_id"></a> [hosted\_zone\_id](#output\_hosted\_zone\_id) | The hosted zone ID of the CloudFront distribution. |
| <a name="output_id"></a> [id](#output\_id) | The ID of the CloudFront distribution. |

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.13.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_route53_record.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alias_name"></a> [alias\_name](#input\_alias\_name) | The DNS name of the target resource (e.g., the CloudFront distribution's domain name). | `string` | n/a | yes |
| <a name="input_alias_target_domain_name"></a> [alias\_target\_domain\_name](#input\_alias\_target\_domain\_name) | The target domain name for the alias record. | `string` | `""` | no |
| <a name="input_alias_zone_id"></a> [alias\_zone\_id](#input\_alias\_zone\_id) | The hosted zone ID of the target resource (e.g., the CloudFront distribution's hosted zone ID). | `string` | n/a | yes |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | The apex domain name (e.g., kconley.com). | `string` | n/a | yes |
| <a name="input_record_names"></a> [record\_names](#input\_record\_names) | A list of record names to create. Use '@' for the apex domain. | `list(string)` | <pre>[<br/>  "@",<br/>  "www"<br/>]</pre> | no |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | The ID of the Route 53 hosted zone where the records will be created. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_fqdns"></a> [fqdns](#output\_fqdns) | A map of the created records and their fully qualified domain names. |

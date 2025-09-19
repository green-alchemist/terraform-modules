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
| [aws_subnet.public_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | A map of Availability Zones to CIDR blocks for the public subnets. | `map(string)` | n/a | yes |
| <a name="input_subnet_availability_zone"></a> [subnet\_availability\_zone](#input\_subnet\_availability\_zone) | The Availability Zone of the Public Subnet | `string` | `"us-east-1a"` | no |
| <a name="input_subnet_cidr_block"></a> [subnet\_cidr\_block](#input\_subnet\_cidr\_block) | The IPv4 CIDR block of the Public Subnet | `string` | `"10.0.1.0/24"` | no |
| <a name="input_subnet_name"></a> [subnet\_name](#input\_subnet\_name) | The Name of the Public Subnet | `string` | `"Free Tier Public Subnet"` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the VPC | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_public_subnet_arn"></a> [public\_subnet\_arn](#output\_public\_subnet\_arn) | The ARN of the Public Subnet |
| <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids) | A list of the public subnet IDs. |
| <a name="output_subnet_ids_map"></a> [subnet\_ids\_map](#output\_subnet\_ids\_map) | A map of the public subnet IDs, keyed by Availability Zone. |

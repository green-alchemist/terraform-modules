## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.14.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_subnet.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_assign_public_ip_on_launch"></a> [assign\_public\_ip\_on\_launch](#input\_assign\_public\_ip\_on\_launch) | If true, instances launched into this subnet will be assigned a public IP address. | `bool` | `false` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | A prefix to use for the subnet names (e.g., 'public' or 'private'). | `string` | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | A map of Availability Zones to CIDR blocks for the subnets. | `map(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to the resources. | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the VPC. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_private_subnets_map"></a> [private\_subnets\_map](#output\_private\_subnets\_map) | A map of the created private subnet objects. |
| <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids) | A list of the private subnet IDs. |

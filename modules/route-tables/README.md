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
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_private_route_table"></a> [create\_private\_route\_table](#input\_create\_private\_route\_table) | Flag to control the creation of a private route table. | `bool` | `false` | no |
| <a name="input_create_public_route_table"></a> [create\_public\_route\_table](#input\_create\_public\_route\_table) | Flag to control the creation of a public route table. | `bool` | `false` | no |
| <a name="input_internet_gateway_id"></a> [internet\_gateway\_id](#input\_internet\_gateway\_id) | The ID of the Internet Gateway for the public route table. | `string` | `null` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | A prefix for the names of the route tables. | `string` | n/a | yes |
| <a name="input_private_subnets_map"></a> [private\_subnets\_map](#input\_private\_subnets\_map) | A map of private subnet objects to associate with the private route table. | `map(object({ id = string }))` | `{}` | no |
| <a name="input_public_subnets_map"></a> [public\_subnets\_map](#input\_public\_subnets\_map) | A map of public subnet objects to associate with the public route table. | `map(object({ id = string }))` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to the resources. | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the VPC. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_private_route_table_id"></a> [private\_route\_table\_id](#output\_private\_route\_table\_id) | The ID of the private Route Table. |
| <a name="output_public_route_table_id"></a> [public\_route\_table\_id](#output\_public\_route\_table\_id) | The ID of the public Route Table. |

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_apigatewayv2_api.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api) | resource |
| [aws_apigatewayv2_integration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_integration) | resource |
| [aws_apigatewayv2_route.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_stage.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_stage) | resource |
| [aws_vpc_link.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_link) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_container_port"></a> [container\_port](#input\_container\_port) | The port of the target container. | `number` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The name for the API Gateway and related resources. | `string` | n/a | yes |
| <a name="input_private_dns_name"></a> [private\_dns\_name](#input\_private\_dns\_name) | The private DNS name of the target service. | `string` | n/a | yes |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | A list of security group IDs for the VPC Link. | `list(string)` | n/a | yes |
| <a name="input_stage_name"></a> [stage\_name](#input\_stage\_name) | The name of the deployment stage (e.g., 'staging'). | `string` | `"$default"` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | A list of subnet IDs for the VPC Link. | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_endpoint"></a> [api\_endpoint](#output\_api\_endpoint) | The invocation URL of the API Gateway. |
| <a name="output_api_id"></a> [api\_id](#output\_api\_id) | The ID of the API Gateway. |

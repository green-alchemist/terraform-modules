## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.13.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_lambda_scale_up"></a> [lambda\_scale\_up](#module\_lambda\_scale\_up) | git@github.com:green-alchemist/terraform-modules.git//modules/lambda-scale-up | n/a |
| <a name="module_step_function"></a> [step\_function](#module\_step\_function) | git@github.com:green-alchemist/terraform-modules.git//modules/step-function | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_apigatewayv2_api.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api) | resource |
| [aws_apigatewayv2_api_mapping.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api_mapping) | resource |
| [aws_apigatewayv2_domain_name.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_domain_name) | resource |
| [aws_apigatewayv2_integration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_integration) | resource |
| [aws_apigatewayv2_route.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_stage.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_stage) | resource |
| [aws_apigatewayv2_vpc_link.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_vpc_link) | resource |
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_role.api_gateway_sfn_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.api_gateway_sfn_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_lambda_permission.apigw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acm_certificate_arn"></a> [acm\_certificate\_arn](#input\_acm\_certificate\_arn) | The ARN of the ACM certificate for the custom domain. | `string` | n/a | yes |
| <a name="input_cloud_map_service_id"></a> [cloud\_map\_service\_id](#input\_cloud\_map\_service\_id) | The Cloud Map service ID for listing instances (for Lambda proxy). | `string` | `""` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The ECS cluster name (for Lambda proxy scale-up). | `string` | `""` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | The custom domain name for the API Gateway. | `string` | n/a | yes |
| <a name="input_enable_access_logging"></a> [enable\_access\_logging](#input\_enable\_access\_logging) | Set to true to enable access logging for the API Gateway stage. | `bool` | `false` | no |
| <a name="input_enable_lambda_proxy"></a> [enable\_lambda\_proxy](#input\_enable\_lambda\_proxy) | Enable the nested Lambda proxy for scale-to-zero (overrides integration\_type to 'AWS\_PROXY'). | `bool` | `false` | no |
| <a name="input_integration_timeout_millis"></a> [integration\_timeout\_millis](#input\_integration\_timeout\_millis) | The timeout in milliseconds for the API Gateway integration. | `number` | `60000` | no |
| <a name="input_integration_type"></a> [integration\_type](#input\_integration\_type) | The integration type. Supported values: 'HTTP\_PROXY' (for VPC Link), 'AWS\_PROXY' (for Lambda). | `string` | n/a | yes |
| <a name="input_integration_uri"></a> [integration\_uri](#input\_integration\_uri) | The integration URI. For Lambda, this is the function's invoke ARN. For HTTP\_PROXY, this is the target URI (e.g., Cloud Map service). | `string` | n/a | yes |
| <a name="input_lambda_security_group_ids"></a> [lambda\_security\_group\_ids](#input\_lambda\_security\_group\_ids) | A list of security group IDs for the Lambda. Required for 'HTTP\_PROXY' integration. | `list(string)` | `[]` | no |
| <a name="input_log_retention_in_days"></a> [log\_retention\_in\_days](#input\_log\_retention\_in\_days) | The number of days to retain the access logs. | `number` | `7` | no |
| <a name="input_name"></a> [name](#input\_name) | The name for the API Gateway and related resources. | `string` | n/a | yes |
| <a name="input_route_keys"></a> [route\_keys](#input\_route\_keys) | A list of route keys to create for the integration. | `list(string)` | <pre>[<br/>  "ANY /{proxy+}"<br/>]</pre> | no |
| <a name="input_service_connect_namespace"></a> [service\_connect\_namespace](#input\_service\_connect\_namespace) | The Cloud Map namespace for Service Connect (for Lambda proxy). | `string` | `""` | no |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | The ECS service name (for Lambda proxy scale-up). | `string` | `""` | no |
| <a name="input_stage_name"></a> [stage\_name](#input\_stage\_name) | The name of the deployment stage (e.g., '$default'). | `string` | `"$default"` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | A list of subnet IDs for the VPC Link. Required for 'HTTP\_PROXY' integration. | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to the resources. | `map(string)` | `{}` | no |
| <a name="input_target_port"></a> [target\_port](#input\_target\_port) | The target port for the ECS service (for Lambda proxy). | `number` | `1337` | no |
| <a name="input_throttling_burst_limit"></a> [throttling\_burst\_limit](#input\_throttling\_burst\_limit) | The throttling burst limit for the API. | `number` | `10000` | no |
| <a name="input_throttling_rate_limit"></a> [throttling\_rate\_limit](#input\_throttling\_rate\_limit) | The throttling rate limit for the API. | `number` | `5000` | no |
| <a name="input_vpc_link_security_group_ids"></a> [vpc\_link\_security\_group\_ids](#input\_vpc\_link\_security\_group\_ids) | A list of security group IDs for the VPC Link. Required for 'HTTP\_PROXY' integration. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_endpoint"></a> [api\_endpoint](#output\_api\_endpoint) | The invocation URL of the API Gateway. |
| <a name="output_api_gateway_hosted_zone_id"></a> [api\_gateway\_hosted\_zone\_id](#output\_api\_gateway\_hosted\_zone\_id) | The hosted zone ID of the API Gateway custom domain name. |
| <a name="output_api_gateway_target_domain_name"></a> [api\_gateway\_target\_domain\_name](#output\_api\_gateway\_target\_domain\_name) | The target domain name of the API Gateway custom domain. |
| <a name="output_api_id"></a> [api\_id](#output\_api\_id) | The ID of the API Gateway. |
| <a name="output_execution_arn"></a> [execution\_arn](#output\_execution\_arn) | The execution ARN of the API Gateway. |

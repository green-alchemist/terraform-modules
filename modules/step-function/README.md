## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.15.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.sfn_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_role.sfn_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.sfn_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_sfn_state_machine.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sfn_state_machine) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_definition"></a> [definition](#input\_definition) | Custom Step Function definition (JSON string). If empty, uses default definition. | `string` | `""` | no |
| <a name="input_enable_logging"></a> [enable\_logging](#input\_enable\_logging) | Set to true to enable CloudWatch logging for the state machine. | `bool` | `true` | no |
| <a name="input_include_execution_data"></a> [include\_execution\_data](#input\_include\_execution\_data) | Determines whether execution data is included in your log. When set to false, data is excluded. | `bool` | `true` | no |
| <a name="input_lambda_function_arn"></a> [lambda\_function\_arn](#input\_lambda\_function\_arn) | ARN of the Lambda function to be invoked by the state machine. | `string` | n/a | yes |
| <a name="input_log_level"></a> [log\_level](#input\_log\_level) | Determines the logging level for the state machine. Valid values: ALL, ERROR, FATAL, OFF. | `string` | `"ALL"` | no |
| <a name="input_state_machine_name"></a> [state\_machine\_name](#input\_state\_machine\_name) | Name for the Step Function state machine. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to the resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_state_machine_arn"></a> [state\_machine\_arn](#output\_state\_machine\_arn) | The ARN of the Step Function state machine. |
| <a name="output_state_machine_name"></a> [state\_machine\_name](#output\_state\_machine\_name) | The name of the Step Function state machine. |

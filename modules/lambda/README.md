## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | 2.7.1 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.14.1 |
| <a name="provider_external"></a> [external](#provider\_external) | 2.3.5 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_lambda_function.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_layer_version.python_packages](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_layer_version) | resource |
| [aws_s3_bucket.lambda_artifacts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_versioning.lambda_artifacts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [archive_file.lambda_package](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [external_external.python_lambda_layer_s3](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_lambda_configs"></a> [lambda\_configs](#input\_lambda\_configs) | List of Lambda configurations (name, code, timeout, memory, permissions, env vars, VPC) | <pre>list(object({<br/>    name            = string<br/>    code            = string<br/>    filename        = optional(string)<br/>    python_packages = optional(list(string), [])<br/>    timeout         = number<br/>    memory_size     = number<br/>    permissions = list(object({<br/>      Action   = string<br/>      Resource = string<br/>    }))<br/>    environment = map(string)<br/>    vpc_config = object({<br/>      subnet_ids         = list(string)<br/>      security_group_ids = list(string)<br/>    })<br/>  }))</pre> | `[]` | no |
| <a name="input_lambda_name"></a> [lambda\_name](#input\_lambda\_name) | Lambda name. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_lambda_arns"></a> [lambda\_arns](#output\_lambda\_arns) | Map of Lambda ARNs, keyed by Lambda configuration name. |
| <a name="output_lambda_function_names"></a> [lambda\_function\_names](#output\_lambda\_function\_names) | Map of Lambda function names, keyed by Lambda configuration name. |
| <a name="output_lambda_invoke_arns"></a> [lambda\_invoke\_arns](#output\_lambda\_invoke\_arns) | Map of Lambda invoke ARNs, keyed by Lambda configuration name. |
